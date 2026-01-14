//
//  Logger.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation
import os.log

/// Centralized logging utility
final class Logger {
    
    enum Level: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        case critical = "🔥 CRITICAL"
    }
    
    // MARK: - Properties
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "DynamicFeatureModule"
    private static var isEnabled: Bool {
        ConfigurationManager.App.loggingEnabled
    }
    
    // MARK: - Logging Methods
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    static func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private static func log(_ message: String, level: Level, file: String, function: String, line: Int) {
        guard isEnabled else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        let logMessage = """
        [\(timestamp)] \(level.rawValue)
        📄 \(fileName):\(line) - \(function)
        💬 \(message)
        """
        
        print(logMessage)
    }
    
    private static func osLogType(for level: Level) -> OSLogType {
        switch level {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
}

// MARK: - Module-specific logging

extension Logger {
    
    struct Module {
        static func downloadStarted(moduleId: String) {
            Logger.info("Module download started: \(moduleId)")
        }
        
        static func downloadProgress(moduleId: String, progress: Double) {
            Logger.debug("Module \(moduleId) download progress: \(Int(progress * 100))%")
        }
        
        static func downloadCompleted(moduleId: String) {
            Logger.info("Module download completed: \(moduleId)")
        }
        
        static func downloadFailed(moduleId: String, error: Error) {
            Logger.error("Module download failed: \(moduleId) - Error: \(error.localizedDescription)")
        }
        
        static func loadStarted(moduleId: String) {
            Logger.info("Module load started: \(moduleId)")
        }
        
        static func loadCompleted(moduleId: String) {
            Logger.info("Module load completed: \(moduleId)")
        }
        
        static func loadFailed(moduleId: String, error: Error) {
            Logger.error("Module load failed: \(moduleId) - Error: \(error.localizedDescription)")
        }
    }
}
