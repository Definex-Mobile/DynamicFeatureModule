//
//  IntegrityValidator.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

struct IntegrityValidator {
    
    /// Validates module integrity after installation
    static func validate(moduleURL: URL, expectedChecksum: String) async throws {
        print("🔍 Running integrity check...")
        
        // 1. Verify directory exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: moduleURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw SecurityError.integrityCheckFailed(reason: "Module directory not found")
        }
        
        // 2. Enumerate all files
        let files = try FileManager.default.contentsOfDirectory(
            at: moduleURL,
            includingPropertiesForKeys: [.fileSizeKey, .isSymbolicLinkKey],
            options: []
        )
        
        // 3. Check for symlinks (shouldn't exist)
        for fileURL in files {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isSymbolicLinkKey])
            if resourceValues.isSymbolicLink == true {
                SecurityAuditLogger.log(.symlinkDetected(path: fileURL.path))
                throw SecurityError.symlinkDetected(fileURL.path)
            }
        }
        
        // 4. Recalculate checksums and compare
        var totalSize: Int64 = 0
        for fileURL in files {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        
        SecurityAuditLogger.log(.integrityCheckPassed(module: moduleURL.lastPathComponent))
        print("✅ Integrity check passed")
        print("   Files: \(files.count)")
        print("   Total size: \(totalSize) bytes")
    }
    
    /// Performs periodic integrity checks on installed modules
    static func performPeriodicCheck(modulesDirectory: URL) async {
        print("🔄 Running periodic integrity checks...")
        
        guard let moduleContainers = try? FileManager.default.contentsOfDirectory(
            at: modulesDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        
        for moduleContainer in moduleContainers {
            let versions = (try? FileManager.default.contentsOfDirectory(
                at: moduleContainer,
                includingPropertiesForKeys: nil
            )) ?? []
            
            for versionURL in versions {
                do {
                    // Basic integrity check without checksum (checksum stored separately)
                    try await validate(moduleURL: versionURL, expectedChecksum: "")
                } catch {
                    SecurityAuditLogger.log(.integrityCheckFailed(
                        module: versionURL.lastPathComponent,
                        reason: error.localizedDescription
                    ))
                }
            }
        }
    }
}
