//
//  QuarantineManager.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

protocol QuarantineManagerProtocol {
    func quarantine(moduleId: String, path: URL, reason: String) async throws
    func release(moduleId: String) async throws
    func delete(moduleId: String) async throws
    func listQuarantined() async -> [QuarantineEntry]
}

final class QuarantineManager: QuarantineManagerProtocol {
    
    private var quarantinedModules: [String: QuarantineEntry] = [:]
    private let quarantineDirectory: URL
    
    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.quarantineDirectory = documentsURL.appendingPathComponent("Quarantine")
        
        try? FileManager.default.createDirectory(
            at: quarantineDirectory,
            withIntermediateDirectories: true
        )
    }
    
    /// Quarantines a suspicious module
    func quarantine(moduleId: String, path: URL, reason: String) async throws {
        let quarantinePath = quarantineDirectory.appendingPathComponent(moduleId)
        
        // Move to quarantine
        try FileManager.default.moveItem(at: path, to: quarantinePath)
        
        let entry = QuarantineEntry(
            moduleId: moduleId,
            reason: reason,
            timestamp: Date(),
            originalPath: path,
            quarantinePath: quarantinePath
        )
        
        quarantinedModules[moduleId] = entry
        
        SecurityAuditLogger.log(.moduleQuarantined(module: moduleId, reason: reason))
        
        print("🔒 Module quarantined: \(moduleId)")
        print("   Reason: \(reason)")
    }
    
    /// Releases module from quarantine after manual review
    func release(moduleId: String) async throws {
        guard let entry = quarantinedModules[moduleId] else {
            throw SecurityError.moduleNotInQuarantine(moduleId: moduleId)
        }
        
        // Move back to original location
        try FileManager.default.moveItem(at: entry.quarantinePath, to: entry.originalPath)
        
        quarantinedModules.removeValue(forKey: moduleId)
        
        SecurityAuditLogger.log(.quarantineReleased(module: moduleId))
        
        print("🔓 Module released from quarantine: \(moduleId)")
    }
    
    /// Permanently deletes quarantined module
    func delete(moduleId: String) async throws {
        guard let entry = quarantinedModules[moduleId] else {
            throw SecurityError.moduleNotInQuarantine(moduleId: moduleId)
        }
        
        try FileManager.default.removeItem(at: entry.quarantinePath)
        quarantinedModules.removeValue(forKey: moduleId)
        
        print("🗑️  Quarantined module deleted: \(moduleId)")
    }
    
    /// Lists all quarantined modules
    func listQuarantined() async -> [QuarantineEntry] {
        return Array(quarantinedModules.values)
    }
}
