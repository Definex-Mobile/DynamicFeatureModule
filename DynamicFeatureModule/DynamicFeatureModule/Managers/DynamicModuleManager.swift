//
//  DynamicModuleManager.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

final class DynamicModuleManager {
    
    static let shared = DynamicModuleManager()
    
    private let apiClient: ModuleAPIClient
    private let downloadManager: BackgroundDownloadManager
    private let storageManager: ModuleStorageManager
    
    private var loadedModules: [String: URL] = [:]
    
    private init() {
        self.apiClient = ModuleAPIClient.shared
        self.downloadManager = BackgroundDownloadManager.shared
        self.storageManager = ModuleStorageManager.shared
    }
    
    // MARK: - Public API
    
    func fetchAvailableModules(completion: @escaping (Result<[ModuleMetadata], ModuleError>) -> Void) {
        apiClient.fetchAvailableModules { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func downloadModule(
        metadata: ModuleMetadata,
        progress: DownloadProgressHandler? = nil,
        completion: @escaping (Result<URL, ModuleError>) -> Void
    ) {
        if let existingContent = storageManager.getModuleContent(
            moduleId: metadata.id,
            version: metadata.version
        ) {
            print("✅ Module \(metadata.id) v\(metadata.version.stringValue) already exists")
            completion(.success(existingContent))
            return
        }
        
        downloadManager.downloadModule(metadata: metadata, progress: progress) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let zipURL):
                self.processDownloadedModule(zipURL: zipURL, metadata: metadata, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getModule(id: String, version: ModuleVersion) -> URL? {
        if let url = loadedModules[id] {
            return url
        }
        
        if let contentURL = storageManager.getModuleContent(moduleId: id, version: version) {
            loadedModules[id] = contentURL
            return contentURL
        }
        
        return nil
    }
    
    func moduleExists(id: String, version: ModuleVersion) -> Bool {
        return storageManager.moduleExists(moduleId: id, version: version)
    }
    
    func listStoredModules() -> [String] {
        return (try? storageManager.listStoredModules()) ?? []
    }
    
    func removeModule(id: String, version: ModuleVersion) throws {
        try ModuleFileManager.shared.removeModule(moduleId: id, version: version)
        loadedModules.removeValue(forKey: id)
        print("🗑️ Removed module: \(id) v\(version.stringValue)")
    }
    
    // MARK: - Private Methods
    
    private func processDownloadedModule(
        zipURL: URL,
        metadata: ModuleMetadata,
        completion: @escaping (Result<URL, ModuleError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. Validate checksum
                print("🔐 Validating checksum for \(metadata.id)...")
                let isValid = try SHA256Validator.validate(
                    fileURL: zipURL,
                    expectedChecksum: metadata.checksum
                )
                
                guard isValid else {
                    throw ModuleError.checksumMismatch(
                        expected: metadata.checksum,
                        actual: "invalid"
                    )
                }
                
                print("✅ Checksum validated")
                
                // 2. Store and extract module
                print("📦 Extracting module \(metadata.id)...")
                let contentURL = try self.storageManager.storeModule(
                    zipURL: zipURL,
                    metadata: metadata
                )
                
                print("✅ Module \(metadata.id) v\(metadata.version.stringValue) ready at: \(contentURL.path)")
                
                // 3. Cache in memory
                self.loadedModules[metadata.id] = contentURL
                
                DispatchQueue.main.async {
                    completion(.success(contentURL))
                }
                
            } catch {
                DispatchQueue.main.async {
                    if let moduleError = error as? ModuleError {
                        completion(.failure(moduleError))
                    } else {
                        completion(.failure(.storageError(error)))
                    }
                }
            }
        }
    }
    
    // MARK: - Version Management
    
    func checkForUpdate(
        currentModuleId: String,
        currentVersion: ModuleVersion,
        completion: @escaping (Result<ModuleMetadata?, ModuleError>) -> Void
    ) {
        apiClient.fetchModule(id: currentModuleId) { result in
            switch result {
            case .success(let remoteMetadata):
                if remoteMetadata.version > currentVersion {
                    completion(.success(remoteMetadata))
                } else {
                    completion(.success(nil))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
