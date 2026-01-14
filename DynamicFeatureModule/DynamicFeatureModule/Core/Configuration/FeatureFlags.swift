//
//  FeatureFlags.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

struct FeatureFlags {
    
    // MARK: - Module Features
    static var parallelDownloads: Bool {
        switch ConfigurationManager.shared.environment {
        case .development, .test:
            return true
        case .production:
            return true
        }
    }
    
    static var moduleCaching: Bool {
        return true
    }
    
    static var modulePreloading: Bool {
        switch ConfigurationManager.shared.environment {
        case .development:
            return true
        case .test, .production:
            return false
        }
    }
    
    // MARK: - Debug Features
    static var debugOverlay: Bool {
        return ConfigurationManager.App.isDebug
    }
        
    static var verboseLogging: Bool {
        switch ConfigurationManager.shared.environment {
        case .development, .test:
            return true
        case .production:
            return false
        }
    }
    
    static var performanceMonitoring: Bool {
        return !ConfigurationManager.App.isDebug
    }
    
    // MARK: - Analytics
        
    static var analytics: Bool {
        return ConfigurationManager.App.analyticsEnabled
    }
    
    static var crashReporting: Bool {
        return BuildConfiguration.enableCrashReporting
    }
    
    // MARK: - Experimental Features
    
    static var experimentalModuleFormats: Bool {
        return BuildConfiguration.enableExperimentalFeatures
    }
    
    static var abTesting: Bool {
        switch ConfigurationManager.shared.environment {
        case .development:
            return false
        case .test, .production:
            return true
        }
    }
}
