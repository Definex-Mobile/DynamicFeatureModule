//
//  AtomicInstaller.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

final class AtomicInstaller {
    
    private let fileManager = FileManager.default
    
    /// Atomically installs a module using a staging directory
    /// Either everything succeeds or everything is rolled back
    func install(sourceURL: URL, moduleName: String, version: String) throws -> URL {
        
        print("⚛️  Starting atomic installation...")
        print("   Module: \(moduleName) v\(version)")
        
        // 1. Setup paths
        let modulesDirectory = try getModulesDirectory()
        let stagingDirectory = try createStagingDirectory()
        let finalDirectory = modulesDirectory
            .appendingPathComponent(moduleName)
            .appendingPathComponent(version)
        let backupDirectory = try createBackupDirectory()
        
        // Track backup location for rollback
        var backupURL: URL?
        
        do {
            // 2. Check if module already exists
            let moduleExists = fileManager.fileExists(atPath: finalDirectory.path)
            
            if moduleExists {
                print("   ⚠️  Existing version found, creating backup...")
                
                // Backup existing version
                let backupName = "\(moduleName)_\(version)_\(Date().timeIntervalSince1970)"
                backupURL = backupDirectory.appendingPathComponent(backupName)
                
                try fileManager.moveItem(at: finalDirectory, to: backupURL!)
                print("   ✅ Backup created")
            }
            
            // 3. Copy to staging directory
            print("   📦 Copying to staging...")
            let stagedURL = stagingDirectory.appendingPathComponent(moduleName)
            try fileManager.copyItem(at: sourceURL, to: stagedURL)
            
            // 4. Validate staged content
            print("   🔍 Validating staged content...")
            try validateInstalledModule(at: stagedURL)
            
            // 5. Create final directory structure
            let moduleContainer = finalDirectory.deletingLastPathComponent()
            try fileManager.createDirectory(
                at: moduleContainer,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // 6. Atomic move from staging to final location
            print("   🚀 Moving to final location...")
            try fileManager.moveItem(at: stagedURL, to: finalDirectory)
            
            // 7. Verify final installation
            try validateInstalledModule(at: finalDirectory)
            
            // 8. Cleanup
            try? fileManager.removeItem(at: stagingDirectory)
            
            // 9. Remove backup after successful install
            if let backupURL = backupURL {
                try? fileManager.removeItem(at: backupURL)
                print("   🗑️  Backup removed")
            }
            
            print("✅ Atomic installation completed successfully")
            print("   Location: \(finalDirectory.path)")
            
            return finalDirectory
            
        } catch {
            // Rollback on any error
            print("❌ Installation failed, rolling back...")
            
            // Remove partial installation
            try? fileManager.removeItem(at: finalDirectory)
            try? fileManager.removeItem(at: stagingDirectory)
            
            // Restore backup if it exists
            if let backupURL = backupURL,
               fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.moveItem(at: backupURL, to: finalDirectory)
                print("   ↩️  Backup restored")
            }
            
            throw SecurityError.installationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Helpers
    
    private func getModulesDirectory() throws -> URL {
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let modulesURL = documentsURL.appendingPathComponent("Modules")
        
        try fileManager.createDirectory(
            at: modulesURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        return modulesURL
    }
    
    private func createStagingDirectory() throws -> URL {
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent("ModuleStaging")
            .appendingPathComponent(UUID().uuidString)
        
        try fileManager.createDirectory(
            at: tempURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        return tempURL
    }
    
    private func createBackupDirectory() throws -> URL {
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let backupURL = documentsURL.appendingPathComponent("ModuleBackups")
        
        try fileManager.createDirectory(
            at: backupURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        return backupURL
    }
    
    private func validateInstalledModule(at url: URL) throws {
        // Ensure directory exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw SecurityError.installationFailed("Module directory not found")
        }
        
        // Ensure it contains files
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey]
        )
        
        guard !contents.isEmpty else {
            throw SecurityError.installationFailed("Module is empty")
        }
        
        // Additional validation: Check for index.html (for web modules)
        let indexExists = contents.contains { $0.lastPathComponent == "index.html" }
        
        if !indexExists {
            print("   ⚠️  Warning: No index.html found")
        }
    }
}
