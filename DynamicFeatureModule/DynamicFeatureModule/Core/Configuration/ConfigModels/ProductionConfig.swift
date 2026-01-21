//
//  ProductionConfig.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

// MARK: - Production Configuration

struct ProductionConfig: AppEnvironmentConfigurable {
    let baseURL = URL(string: "http://localhost:8000")!
    let moduleRepositoryURL = URL(string: "http://localhost:8000/modules")!
    let apiKey = "dev-api-key-12345"
    let debugMode = false
    let loggingEnabled = false
    let analyticsEnabled = true
    let maxConcurrentDownloads = 5
    let cacheExpirationTime: TimeInterval = 3600 // 1 hour
}
