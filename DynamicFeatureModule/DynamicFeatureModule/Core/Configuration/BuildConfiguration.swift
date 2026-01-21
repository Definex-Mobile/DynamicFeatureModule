//
//  BuildConfiguration.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

/// Build configuration information
struct BuildConfiguration {
    
    // MARK: - Build Info
    
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
    
    static var versionNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.serkan.kara.dynamicfeaturemodule"
    }
    
    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "DynamicFeatureModule"
    }
    
    // MARK: - Environment Info
    
    static var environment: Environment {
        ConfigurationManager.shared.environment
    }
    
    static var fullVersionString: String {
        "\(versionNumber) (\(buildNumber)) - \(environment.displayName)"
    }
    
    // MARK: - Compiler Flags
    
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isTestBuild: Bool {
        #if TEST
        return true
        #else
        return false
        #endif
    }
    
    static var isProductionBuild: Bool {
        #if PRODUCTION
        return true
        #else
        return false
        #endif
    }
}
