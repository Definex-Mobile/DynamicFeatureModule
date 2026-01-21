//
//  AppEnvironmentConfigurable.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

// MARK: - Environment Configuration Protocol

protocol AppEnvironmentConfigurable {
    var baseURL: URL { get }
    var moduleRepositoryURL: URL { get }
    var apiKey: String { get }
    var debugMode: Bool { get }
    var loggingEnabled: Bool { get }
    var analyticsEnabled: Bool { get }
    var maxConcurrentDownloads: Int { get }
    var cacheExpirationTime: TimeInterval { get }
}
