//
//  ConfigurationManager.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

final class ConfigurationManager {
    
    static let shared = ConfigurationManager()
    
    // MARK: - Properties
    
    private(set) var environment: Environment
    private(set) var configuration: EnvironmentConfigurable
    
    // MARK: - Initialization
    
    private init() {
        self.environment = Environment.current
        
        switch environment {
        case .development:
            self.configuration = DevelopmentConfiguration()
        case .test:
            self.configuration = TestConfiguration()
        case .production:
            self.configuration = ProductionConfiguration()
        }
        
        setupEnvironment()
    }
    
    // MARK: - Setup
    
    private func setupEnvironment() {
        if configuration.loggingEnabled {
            print("🚀 Application started in \(environment.displayName) environment")
            print("📍 Base URL: \(configuration.baseURL)")
            print("📦 Module Repository: \(configuration.moduleRepositoryURL)")
            print("🔧 Debug Mode: \(configuration.debugMode)")
        }
    }
    
    // MARK: - Public Methods
    
    func infoPlistValue(for key: String) -> Any? {
        return Bundle.main.object(forInfoDictionaryKey: key)
    }
    
    var isDebugMode: Bool {
        return configuration.debugMode
    }
    
    var isLoggingEnabled: Bool {
        return configuration.loggingEnabled
    }
    
    var isAnalyticsEnabled: Bool {
        return configuration.analyticsEnabled
    }
}

// MARK: - Convenience Extensions

extension ConfigurationManager {
    
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
    
    struct App {
        static var environment: Environment {
            ConfigurationManager.shared.environment
        }
        
        static var isDebug: Bool {
            ConfigurationManager.shared.isDebugMode
        }
        
        static var loggingEnabled: Bool {
            ConfigurationManager.shared.isLoggingEnabled
        }
        
        static var analyticsEnabled: Bool {
            ConfigurationManager.shared.isAnalyticsEnabled
        }
        
        static var maxConcurrentDownloads: Int {
            ConfigurationManager.shared.configuration.maxConcurrentDownloads
        }
        
        static var cacheExpirationTime: TimeInterval {
            ConfigurationManager.shared.configuration.cacheExpirationTime
        }
    }
}
