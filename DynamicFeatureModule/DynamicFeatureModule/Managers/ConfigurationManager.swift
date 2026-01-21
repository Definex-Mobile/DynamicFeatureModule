//
//  ConfigurationManager.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

// MARK: - Configuration Manager

final class ConfigurationManager {
    
    // MARK: - Singleton
    
    static let shared = ConfigurationManager()
    
    // MARK: - Properties
    
    let environment: Environment
    let configuration: AppEnvironmentConfigurable
    
    // Backward compatibility for existing code
    var backendURL: String {
        return configuration.baseURL.absoluteString
    }
    
    // MARK: - Initialization
    
    private init() {
        self.environment = Environment.current
        
        switch environment {
        case .development:
            self.configuration = DevelopmentConfig()
        case .test:
            self.configuration = TestConfig()
        case .production:
            self.configuration = ProductionConfig()
        }
        
        setupEnvironment()
    }
    
    // MARK: - Setup
    
    private func setupEnvironment() {
        if configuration.loggingEnabled {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🚀 DynamicFeatureModule Configuration")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🌍 Environment: \(environment.displayName)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
    }
    
    /// Check if logging is enabled
    var isLoggingEnabled: Bool {
        return configuration.loggingEnabled
    }
}

// MARK: - Convenience Extensions

extension ConfigurationManager {
    
    /// API configuration shortcuts
    struct API {
        static var baseURL: URL {
            ConfigurationManager.shared.configuration.baseURL
        }
        
        static var moduleRepositoryURL: URL {
            ConfigurationManager.shared.configuration.moduleRepositoryURL
        }
        
        static var apiKey: String {
            ConfigurationManager.shared.configuration.apiKey
        }
    }
    
    /// App configuration shortcuts
    struct App {
        static var environment: Environment {
            ConfigurationManager.shared.environment
        }
        
        static var loggingEnabled: Bool {
            ConfigurationManager.shared.isLoggingEnabled
        }
        
        static var maxConcurrentDownloads: Int {
            ConfigurationManager.shared.configuration.maxConcurrentDownloads
        }
        
        static var cacheExpirationTime: TimeInterval {
            ConfigurationManager.shared.configuration.cacheExpirationTime
        }
    }
}
