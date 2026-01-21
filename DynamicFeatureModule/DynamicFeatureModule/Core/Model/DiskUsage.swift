//
//  DiskUsage.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

struct DiskUsage {
    let total: Int64
    let used: Int64
    let free: Int64
    let usagePercentage: Double
    
    var isLow: Bool {
        return usagePercentage > 90 || free < 100 * 1024 * 1024 // Less than 100MB
    }
}
