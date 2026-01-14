//
//  EnvironmentConfiguration.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

protocol EnvironmentConfigurable {
    var baseURL: URL { get }
    var moduleRepositoryURL: URL { get }
    var apiKey: String { get }
    var loggingEnabled: Bool { get }
    var analyticsEnabled: Bool { get }
    var debugMode: Bool { get }
    var maxConcurrentDownloads: Int { get }
    var cacheExpirationTime: TimeInterval { get }
}

struct DevelopmentConfiguration: EnvironmentConfigurable {
    var baseURL: URL {
        URL(string: "https://dev-api.DynamicFeatureModule.com")!
    }
    
    var moduleRepositoryURL: URL {
        URL(string: "https://dev-modules.DynamicFeatureModule.com")!
    }
    
    var apiKey: String {
        return "dev_api_key_12345"
    }
    
    var loggingEnabled: Bool {
        return true
    }
    
    var analyticsEnabled: Bool {
        return false
    }
    
    var debugMode: Bool {
        return true
    }
    
    var maxConcurrentDownloads: Int {
        return 5
    }
    
    var cacheExpirationTime: TimeInterval {
        return 300
    }
}

struct TestConfiguration: EnvironmentConfigurable {
    var baseURL: URL {
        URL(string: "https://test-api.DynamicFeatureModule.com")!
    }
    
    var moduleRepositoryURL: URL {
        URL(string: "https://test-modules.DynamicFeatureModule.com")!
    }
    
    var apiKey: String {
        return "test_api_key_67890"
    }
    
    var loggingEnabled: Bool {
        return true
    }
    
    var analyticsEnabled: Bool {
        return true
    }
    
    var debugMode: Bool {
        return true
    }
    
    var maxConcurrentDownloads: Int {
        return 3
    }
    
    var cacheExpirationTime: TimeInterval {
        return 600
    }
}

struct ProductionConfiguration: EnvironmentConfigurable {
    var baseURL: URL {
        URL(string: "https://api.example.com")!
    }
    
    var moduleRepositoryURL: URL {
        URL(string: "https://modules.example.com")!
    }
    
    var apiKey: String {
        return Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? ""
    }
    
    var loggingEnabled: Bool {
        return false
    }
    
    var analyticsEnabled: Bool {
        return true
    }
    
    var debugMode: Bool {
        return false
    }
    
    var maxConcurrentDownloads: Int {
        return 2
    }
    
    var cacheExpirationTime: TimeInterval {
        return 3600
    }
}
