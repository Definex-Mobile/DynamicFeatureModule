//
//  ConnectionType.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 4.02.2026.
//

import Foundation

enum ConnectionType: String, Sendable {
    case none = "None"
    case wifi = "WiFi"
    case cellular = "Cellular"
    case wired = "Wired"
    case loopback = "Loopback"
    case other = "Other"
}
