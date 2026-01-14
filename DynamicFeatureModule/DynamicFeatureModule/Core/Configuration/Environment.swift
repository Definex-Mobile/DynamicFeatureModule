//
//  Environment.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

enum Environment: String, CaseIterable {
    case development = "Development"
    case test = "Test"
    case production = "Production"
    
    static var current: Environment {
        if let bundleId = Bundle.main.bundleIdentifier {
            if bundleId.contains(".dev") {
                return .development
            } else if bundleId.contains(".test") {
                return .test
            } else {
                return .production
            }
        }
        
        #if DEV
        return .development
        #elseif TEST
        return .test
        #elseif PRODUCTION
        return .production
        #elseif DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    var displayName: String {
        return rawValue
    }
    
    var bundleIdSuffix: String {
        switch self {
        case .development:
            return ".dev"
        case .test:
            return ".test"
        case .production:
            return ""
        }
    }
    
    var appNameSuffix: String {
        switch self {
        case .development:
            return " [DEV]"
        case .test:
            return " [TEST]"
        case .production:
            return ""
        }
    }
}
