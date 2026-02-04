//
//  DownloadProgress.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 4.02.2026.
//

import Foundation

// MARK: - UI/Caller facing progress model

struct DownloadProgress: Sendable {
    let fraction: Double
    let bytesReceived: Int64
    let bytesExpected: Int64?
    let bytesPerSecond: Double?
    let etaSeconds: Double?

    var percentInt: Int { Int((fraction * 100).rounded()) }
}
