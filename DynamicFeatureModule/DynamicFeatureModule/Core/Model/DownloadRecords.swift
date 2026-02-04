//
//  DownloadRecords.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 4.02.2026.
//

import Foundation

struct DownloadRecord: Sendable, Equatable {
    let moduleId: String
    let attemptId: UUID
    let startedAt: Date
    let finishedAt: Date
    let success: Bool
    let endReason: DownloadEndReason
    let bytesDownloaded: Int64
    let expectedBytes: Int64?

    var duration: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
}

struct DownloadAttempt: Sendable, Equatable {
    let moduleId: String
    let attemptId: UUID
    let startedAt: Date
    var lastUpdatedAt: Date
    var bytesReceived: Int64
    var expectedBytes: Int64?
}

enum DownloadEndReason: Sendable, Equatable {
    case success
    case cancelled
    case noInternet
    case timeout
    case serverError(statusCode: Int?)
    case checksumMismatch
    case integrityFailed
    case unknown
}
