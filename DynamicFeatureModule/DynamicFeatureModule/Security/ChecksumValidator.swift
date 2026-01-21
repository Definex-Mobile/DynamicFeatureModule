//
//  ChecksumValidator.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation
import CryptoKit

struct ChecksumValidator {
    
    /// Validates file checksum against expected hash
    static func validate(fileURL: URL, expectedChecksum: String) throws {
        let actualChecksum = try generateChecksum(for: fileURL)
        
        guard actualChecksum.lowercased() == expectedChecksum.lowercased() else {
            throw SecurityError.checksumMismatch(
                expected: expectedChecksum,
                actual: actualChecksum
            )
        }
    }
    
    /// Generates SHA-256 checksum for a file
    static func generateChecksum(for fileURL: URL) throws -> String {
        let data = try Data(contentsOf: fileURL)
        
        switch SecurityConfiguration.checksumAlgorithm {
        case .sha256:
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
            
        case .sha512:
            let hash = SHA512.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        }
    }
    
    /// Validates checksum of data in memory (for smaller payloads)
    static func validate(data: Data, expectedChecksum: String) throws {
        let actualChecksum = generateChecksum(for: data)
        
        guard actualChecksum.lowercased() == expectedChecksum.lowercased() else {
            throw SecurityError.checksumMismatch(
                expected: expectedChecksum,
                actual: actualChecksum
            )
        }
    }
    
    /// Generates checksum for data
    static func generateChecksum(for data: Data) -> String {
        switch SecurityConfiguration.checksumAlgorithm {
        case .sha256:
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
            
        case .sha512:
            let hash = SHA512.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        }
    }
}
