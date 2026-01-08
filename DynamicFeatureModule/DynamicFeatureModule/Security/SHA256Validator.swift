//
//  SHA256Validator.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 8.01.2026.
//

import Foundation
import CryptoKit

/// Validates file integrity using SHA-256 checksum
final class SHA256Validator {
    
    /// Compute SHA-256 hash of a file
    static func computeHash(of fileURL: URL) throws -> String {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ModuleError.fileNotFound(fileURL.path)
        }
        
        let data = try Data(contentsOf: fileURL)
        let digest = SHA256.hash(data: data)
        let hashString = digest.map { String(format: "%02x", $0) }.joined()
        
        return hashString
    }
    
    /// Validate file checksum against expected hash
    static func validate(fileURL: URL, expectedChecksum: String) throws -> Bool {
        let actualChecksum = try computeHash(of: fileURL)
        
        // Remove "sha256:" prefix if present
        let cleanExpected = expectedChecksum.replacingOccurrences(of: "sha256:", with: "")
        
        guard actualChecksum.lowercased() == cleanExpected.lowercased() else {
            throw ModuleError.checksumMismatch(expected: cleanExpected, actual: actualChecksum)
        }
        
        return true
    }
}
