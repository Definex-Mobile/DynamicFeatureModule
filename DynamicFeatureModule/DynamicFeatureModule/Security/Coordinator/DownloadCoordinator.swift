//
//  DownloadCoordinator.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

protocol DownloadCoordinatorProtocol {
    func canStartDownload(moduleId: String) async throws
    func completeDownload(moduleId: String, success: Bool, bytesDownloaded: Int64) async
    func getStatistics() async -> DownloadStatistics
}

final class DownloadCoordinator: DownloadCoordinatorProtocol {
    
    // MARK: - State
    
    private var activeDownloads: [String: Date] = [:]
    private var downloadHistory: [DownloadRecord] = []
    private let maxConcurrentDownloads = 3
    
    struct DownloadRecord {
        let moduleId: String
        let timestamp: Date
        let success: Bool
        let bytesDownloaded: Int64
    }
    
    // MARK: - Download Management
    
    /// Checks if a download can proceed
    func canStartDownload(moduleId: String) async throws {
        // 1. Check concurrent download limit
        guard activeDownloads.count < maxConcurrentDownloads else {
            throw SecurityError.tooManyConcurrentDownloads(limit: maxConcurrentDownloads)
        }
        
        // 2. Check if same module is already downloading
        if activeDownloads[moduleId] != nil {
            throw SecurityError.downloadAlreadyInProgress(moduleId: moduleId)
        }
        
        // 3. Check rate limiting
        if let lastDownloadTime = getLastDownloadTime(for: moduleId) {
            let timeSinceLastDownload = Date().timeIntervalSince(lastDownloadTime)
            let cooldown = SecurityConfiguration.downloadCooldown
            
            if timeSinceLastDownload < cooldown {
                let remaining = cooldown - timeSinceLastDownload
                SecurityAuditLogger.log(.rateLimitExceeded(cooldownRemaining: remaining))
                throw SecurityError.rateLimitExceeded(retryAfter: remaining)
            }
        }
        
        // 4. Check download quota (max downloads per hour)
        let recentDownloads = downloadHistory.filter {
            Date().timeIntervalSince($0.timestamp) < 3600
        }
        
        if recentDownloads.count >= SecurityConfiguration.maxDownloadsPerHour {
            throw SecurityError.downloadQuotaExceeded
        }
        
        // Register download
        activeDownloads[moduleId] = Date()
    }
    
    /// Marks download as completed
    func completeDownload(moduleId: String, success: Bool, bytesDownloaded: Int64) async {
        activeDownloads.removeValue(forKey: moduleId)
        
        let record = DownloadRecord(
            moduleId: moduleId,
            timestamp: Date(),
            success: success,
            bytesDownloaded: bytesDownloaded
        )
        
        downloadHistory.append(record)
        
        // Keep only last 100 records
        if downloadHistory.count > 100 {
            downloadHistory.removeFirst(downloadHistory.count - 100)
        }
    }
    
    /// Gets statistics for monitoring
    func getStatistics() async -> DownloadStatistics {
        let totalDownloads = downloadHistory.count
        let successfulDownloads = downloadHistory.filter { $0.success }.count
        let failedDownloads = totalDownloads - successfulDownloads
        let totalBytes = downloadHistory.reduce(0) { $0 + $1.bytesDownloaded }
        
        return DownloadStatistics(
            activeDownloads: activeDownloads.count,
            totalDownloads: totalDownloads,
            successfulDownloads: successfulDownloads,
            failedDownloads: failedDownloads,
            totalBytesDownloaded: totalBytes
        )
    }
    
    // MARK: - Private Helpers
    
    private func getLastDownloadTime(for moduleId: String) -> Date? {
        return downloadHistory
            .filter { $0.moduleId == moduleId }
            .sorted { $0.timestamp > $1.timestamp }
            .first?
            .timestamp
    }
}
