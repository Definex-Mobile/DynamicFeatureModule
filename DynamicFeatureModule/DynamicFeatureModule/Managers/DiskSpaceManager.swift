//
//  DiskSpaceManager.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

protocol DiskSpaceManagerProtocol {
    func checkAvailableSpace(required: Int64) throws
    func getDiskUsage() -> DiskUsage?
}

final class DiskSpaceManager: DiskSpaceManagerProtocol {
    
    /// Checks if sufficient disk space is available
    func checkAvailableSpace(required: Int64) throws {
        let fileManager = FileManager.default
        
        guard let attributes = try? fileManager.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ) else {
            throw SecurityError.diskSpaceCheckFailed
        }
        
        guard let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            throw SecurityError.diskSpaceCheckFailed
        }
        
        // Require 2x the space (for unzip + safety margin)
        let requiredWithBuffer = required * 2
        
        guard freeSpace > requiredWithBuffer else {
            SecurityAuditLogger.log(.insufficientDiskSpace(
                required: requiredWithBuffer,
                available: freeSpace
            ))
            throw SecurityError.insufficientDiskSpace(
                required: requiredWithBuffer,
                available: freeSpace
            )
        }
        
        print("💾 Disk space check: OK")
        print("   Required: \(requiredWithBuffer / 1024 / 1024) MB")
        print("   Available: \(freeSpace / 1024 / 1024) MB")
    }
    
    /// Gets current disk usage statistics
    func getDiskUsage() -> DiskUsage? {
        let fileManager = FileManager.default
        
        guard let attributes = try? fileManager.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ),
              let totalSpace = attributes[.systemSize] as? Int64,
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return nil
        }
        
        let usedSpace = totalSpace - freeSpace
        
        return DiskUsage(
            total: totalSpace,
            used: usedSpace,
            free: freeSpace,
            usagePercentage: Double(usedSpace) / Double(totalSpace) * 100
        )
    }
}
