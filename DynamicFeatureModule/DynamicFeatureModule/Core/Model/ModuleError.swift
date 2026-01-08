//
//  ModuleError.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 8.01.2026.
//

import Foundation

enum ModuleError: LocalizedError {
    case invalidVersion(String)
    case downloadFailed(Error)
    case checksumMismatch(expected: String, actual: String)
    case unzipFailed(Error)
    case fileNotFound(String)
    case networkError(Error)
    case invalidMetadata
    case storageError(Error)
    case moduleNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidVersion(let version):
            return "Invalid version format: \(version)"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .checksumMismatch(let expected, let actual):
            return "Checksum mismatch. Expected: \(expected), Got: \(actual)"
        case .unzipFailed(let error):
            return "Failed to unzip file: \(error.localizedDescription)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidMetadata:
            return "Invalid module metadata"
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        case .moduleNotFound(let id):
            return "Module not found: \(id)"
        }
    }
}
