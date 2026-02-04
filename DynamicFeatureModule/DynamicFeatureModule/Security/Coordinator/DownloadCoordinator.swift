//
//  DownloadCoordinator.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

//
//  DownloadCoordinator.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

protocol DownloadCoordinatorProtocol: Sendable {
    func canStartDownload(moduleId: String) async throws -> UUID
    func updateProgress(moduleId: String, attemptId: UUID, bytesReceived: Int64, expectedBytes: Int64?) async
    func completeDownload(moduleId: String, attemptId: UUID, reason: DownloadEndReason, bytesDownloaded: Int64, expectedBytes: Int64?) async
    func getStatistics() async -> DownloadStatistics
}

// MARK: - Coordinator

actor DownloadCoordinator: DownloadCoordinatorProtocol {

    // MARK: - State

    private var active: [String: DownloadAttempt] = [:]  
    private var history: [DownloadRecord] = []
    private let maxConcurrentDownloads: Int = 3

    // Keep some history, not infinite
    private let maxHistoryCount = 200

    // MARK: - Public API

    /// Call this right before starting the network task.
    func canStartDownload(moduleId: String) async throws -> UUID {
        // 1) concurrency limit
        guard active.count < maxConcurrentDownloads else {
            throw SecurityError.tooManyConcurrentDownloads(limit: maxConcurrentDownloads)
        }

        // 2) same module downloading
        if active[moduleId] != nil {
            throw SecurityError.downloadAlreadyInProgress(moduleId: moduleId)
        }

        // 3) per-module cooldown (based on last attempt finish time)
        if let last = lastFinishedAt(for: moduleId) {
            let dt = Date().timeIntervalSince(last)
            let cooldown = SecurityConfiguration.downloadCooldown
            if dt < cooldown {
                let remaining = cooldown - dt
                SecurityAuditLogger.log(.rateLimitExceeded(cooldownRemaining: remaining))
                throw SecurityError.rateLimitExceeded(retryAfter: remaining)
            }
        }

        // 4) global quota per hour (count attempts ended within last hour)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentCount = history.filter { $0.finishedAt >= oneHourAgo }.count
        if recentCount >= SecurityConfiguration.maxDownloadsPerHour {
            throw SecurityError.downloadQuotaExceeded
        }

        // Register attempt
        let id = UUID()
        let now = Date()

        active[moduleId] = DownloadAttempt(
            moduleId: moduleId,
            attemptId: id,
            startedAt: now,
            lastUpdatedAt: now,
            bytesReceived: 0,
            expectedBytes: nil
        )

        return id
    }

    /// Optional: call from URLSession progress callback if you want coordinator-level observability.
    func updateProgress(
        moduleId: String,
        attemptId: UUID,
        bytesReceived: Int64,
        expectedBytes: Int64?
    ) async {
        guard var a = active[moduleId], a.attemptId == attemptId else { return }
        a.bytesReceived = max(0, bytesReceived)
        a.expectedBytes = expectedBytes
        a.lastUpdatedAt = Date()
        active[moduleId] = a
    }

    /// Must be called exactly once per begun attempt.
    func completeDownload(
        moduleId: String,
        attemptId: UUID,
        reason: DownloadEndReason,
        bytesDownloaded: Int64,
        expectedBytes: Int64?
    ) async {
        let now = Date()

        // Use the real start time if we have it, otherwise fall back safely.
        let startedAt = active[moduleId]?.attemptId == attemptId
        ? (active.removeValue(forKey: moduleId)?.startedAt ?? now)
        : (startedAtFromHistory(moduleId: moduleId, attemptId: attemptId) ?? now)

        let success = (reason == .success)

        let record = DownloadRecord(
            moduleId: moduleId,
            attemptId: attemptId,
            startedAt: startedAt,
            finishedAt: now,
            success: success,
            endReason: reason,
            bytesDownloaded: max(0, bytesDownloaded),
            expectedBytes: expectedBytes
        )

        history.append(record)

        // Trim history
        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
    }

    func getStatistics() async -> DownloadStatistics {
        let total = history.count
        let successCount = history.filter { $0.success }.count
        let failedCount = total - successCount
        let totalBytes = history.reduce(0) { $0 + $1.bytesDownloaded }

        return DownloadStatistics(
            activeDownloads: active.count,
            totalDownloads: total,
            successfulDownloads: successCount,
            failedDownloads: failedCount,
            totalBytesDownloaded: totalBytes
        )
    }

    // MARK: - Helpers

    private func lastFinishedAt(for moduleId: String) -> Date? {
        history
            .filter { $0.moduleId == moduleId }
            .max(by: { $0.finishedAt < $1.finishedAt })?
            .finishedAt
    }

    private func startedAtFromHistory(moduleId: String, attemptId: UUID) -> Date? {
        history.first(where: { $0.moduleId == moduleId && $0.attemptId == attemptId })?.startedAt
    }
}
