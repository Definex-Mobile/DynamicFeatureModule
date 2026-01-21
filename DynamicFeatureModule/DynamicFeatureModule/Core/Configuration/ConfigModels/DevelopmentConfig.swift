//
//  DevelopmentConfig.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

// MARK: - Development Configuration

struct DevelopmentConfig: AppEnvironmentConfigurable {
    let baseURL = URL(string: "http://localhost:8000")!
    let moduleRepositoryURL = URL(string: "http://localhost:8000/modules")!
    let apiKey = "dev-api-key-12345"
    let debugMode = true
    let loggingEnabled = true
    let analyticsEnabled = false
    let maxConcurrentDownloads = 3
    let cacheExpirationTime: TimeInterval = 300 // 5 minutes
}
