//
//  ModuleFileManager.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

final class ModuleFileManager {
    
    static let shared = ModuleFileManager()
    
    private let fileManager = FileManager.default
    
    private lazy var documentsURL: URL = {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()
    
    lazy var modulesBaseURL: URL = {
        let url = documentsURL.appendingPathComponent("DynamicModules/Modules")
        createDirectoryIfNeeded(at: url)
        return url
    }()
    
    lazy var downloadsURL: URL = {
        let url = documentsURL.appendingPathComponent("DynamicModules/Downloads")
        createDirectoryIfNeeded(at: url)
        return url
    }()
    
    private init() {}
    
    // MARK: - Directory Operations
    
    func createDirectoryIfNeeded(at url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    func moduleDirectory(for moduleId: String, version: ModuleVersion) -> URL {
        return modulesBaseURL
            .appendingPathComponent(moduleId)
            .appendingPathComponent("v\(version.stringValue)")
    }
    
    func downloadPath(for moduleId: String) -> URL {
        return downloadsURL.appendingPathComponent("\(moduleId).zip")
    }
    
    // MARK: - File Operations
    
    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    func removeFile(at url: URL) throws {
        if fileExists(at: url) {
            try fileManager.removeItem(at: url)
        }
    }
    
    func moveFile(from source: URL, to destination: URL) throws {
        try removeFile(at: destination)
        try fileManager.moveItem(at: source, to: destination)
    }
    
    func copyFile(from source: URL, to destination: URL) throws {
        try removeFile(at: destination)
        try fileManager.copyItem(at: source, to: destination)
    }
    
    // MARK: - Security
    
    func applyFileProtection(to url: URL) throws {
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }
    
    // MARK: - Cleanup
    
    func removeModule(moduleId: String, version: ModuleVersion) throws {
        let moduleDir = moduleDirectory(for: moduleId, version: version)
        try removeFile(at: moduleDir)
    }
    
    func clearDownloadsDirectory() throws {
        let contents = try fileManager.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: nil)
        for file in contents {
            try removeFile(at: file)
        }
    }
}
