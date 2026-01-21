//
//  QuarantineEntry.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

struct QuarantineEntry {
    let moduleId: String
    let reason: String
    let timestamp: Date
    let originalPath: URL
    let quarantinePath: URL
}
