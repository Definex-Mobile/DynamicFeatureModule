//
//  ModuleStorageManager.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

final class ModuleStorageManager {
    
    static let shared = ModuleStorageManager()
    
    private let fileManager = ModuleFileManager.shared
    private let unarchiver = ZipUnarchiver.shared
    
    private init() {}
    
    func storeModule(
        zipURL: URL,
        metadata: ModuleMetadata
    ) throws -> URL {
        let moduleDir = fileManager.moduleDirectory(
            for: metadata.id,
            version: metadata.version
        )
        fileManager.createDirectoryIfNeeded(at: moduleDir)
        
        let contentDir = moduleDir.appendingPathComponent("content")
        try unarchiver.unzip(fileURL: zipURL, to: contentDir)
        
        let metadataURL = moduleDir.appendingPathComponent("metadata.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: metadataURL)
        
        try fileManager.applyFileProtection(to: moduleDir)
        
        try? fileManager.removeFile(at: zipURL)
        
        return contentDir
    }
    
    func getModuleContent(moduleId: String, version: ModuleVersion) -> URL? {
        let contentDir = fileManager.moduleDirectory(for: moduleId, version: version)
            .appendingPathComponent("content")
        
        return fileManager.fileExists(at: contentDir) ? contentDir : nil
    }
    
    func moduleExists(moduleId: String, version: ModuleVersion) -> Bool {
        return getModuleContent(moduleId: moduleId, version: version) != nil
    }
    
    func getMetadata(moduleId: String, version: ModuleVersion) throws -> ModuleMetadata? {
        let metadataURL = fileManager.moduleDirectory(for: moduleId, version: version)
            .appendingPathComponent("metadata.json")
        
        guard fileManager.fileExists(at: metadataURL) else {
            return nil
        }
        
        let data = try Data(contentsOf: metadataURL)
        let decoder = JSONDecoder()
        return try decoder.decode(ModuleMetadata.self, from: data)
    }
    
    func listStoredModules() throws -> [String] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: fileManager.modulesBaseURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        )
        
        return contents
            .filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            .map { $0.lastPathComponent }
    }
}
