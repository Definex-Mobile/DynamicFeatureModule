//
//  Environment.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

enum Environment: String, CaseIterable {
    case development = "development"
    case test = "test"
    case production = "production"
    
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
}
