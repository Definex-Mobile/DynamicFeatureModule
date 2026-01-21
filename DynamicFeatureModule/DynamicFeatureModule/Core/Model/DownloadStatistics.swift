//
//  DownloadStatistics.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

struct DownloadStatistics {
    let activeDownloads: Int
    let totalDownloads: Int
    let successfulDownloads: Int
    let failedDownloads: Int
    let totalBytesDownloaded: Int64
    
    var successRate: Double {
        guard totalDownloads > 0 else { return 0 }
        return Double(successfulDownloads) / Double(totalDownloads)
    }
}
