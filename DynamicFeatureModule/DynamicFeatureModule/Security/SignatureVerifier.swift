//
//  SignatureVerifier.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation
import CryptoKit
import Security

struct SignatureVerifier {
    
    // MARK: - Public Interface
    
    /// Verifies RSA signature using the public key from SecurityConfiguration
    static func verifyManifest(data: Data, signature: String) throws -> Bool {
        // Decode base64 signature
        guard let signatureData = Data(base64Encoded: signature) else {
            throw SecurityError.invalidSignature
        }
        
        // Parse PEM public key
        let publicKey = try parsePublicKey(SecurityConfiguration.manifestPublicKey)
        
        // Hash the data
        let dataHash = SHA256.hash(data: data)
        let hashData = Data(dataHash)
        
        // Verify signature using Security framework
        let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256
        
        var error: Unmanaged<CFError>?
        let isValid = SecKeyVerifySignature(
            publicKey,
            algorithm,
            hashData as CFData,
            signatureData as CFData,
            &error
        )
        
        if let error = error {
            let errorDescription = error.takeRetainedValue() as Error
            throw SecurityError.signatureVerificationFailed(errorDescription.localizedDescription)
        }
        
        guard isValid else {
            throw SecurityError.invalidSignature
        }
        
        print("🔐 Signature verification: PASSED (production mode)")
        SecurityAuditLogger.log(.signatureVerified(algorithm: "RSA-2048-SHA256"))
        
        return true
    }
    
    /// Verifies manifest with embedded signature and timestamp
    static func verifySignedManifest(_ manifest: SignedManifest) throws {
        print("🔍 Validating signed manifest...")
        
        // Check timestamp to prevent replay attacks
        let manifestAge = Date().timeIntervalSince(manifest.timestamp)
        
        // TEMPORARY: Skip signature verification for development
        #if DEBUG
        print("⚠️  DEBUG MODE: Skipping RSA signature verification")
        
        // Check if timestamp is in the future (clock skew tolerance: 60s)
        if manifestAge < -60 {
            throw SecurityError.manifestTimestampInFuture
        }
        
        guard manifestAge < SecurityConfiguration.maxManifestAge else {
            SecurityAuditLogger.log(.replayAttemptDetected(age: manifestAge))
            throw SecurityError.manifestTooOld
        }
        
        guard manifest.nonce.count >= 16 else {
            throw SecurityError.invalidNonce
        }
        
        print("✅ Manifest validation passed (signature check bypassed in DEBUG)")
        print("   Timestamp: \(manifest.timestamp)")
        print("   Nonce: \(manifest.nonce.prefix(16))...")
        print("   Modules: \(manifest.modules.count)")
        return
        #endif
        
        // PRODUCTION: Full signature verification
        
        // Check if timestamp is in the future (clock skew tolerance: 60s)
        if manifestAge < -60 {
            throw SecurityError.manifestTimestampInFuture
        }
        
        // Check if manifest is too old
        guard manifestAge < SecurityConfiguration.maxManifestAge else {
            SecurityAuditLogger.log(.replayAttemptDetected(age: manifestAge))
            throw SecurityError.manifestTooOld
        }
        
        // Validate nonce format (should be UUID or similar)
        guard manifest.nonce.count >= 16 else {
            throw SecurityError.invalidNonce
        }
        
        // Serialize manifest data (without signature) for verification
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys] // Deterministic serialization
        
        let manifestData = ManifestData(
            modules: manifest.modules,
            timestamp: manifest.timestamp,
            nonce: manifest.nonce,
            environment: manifest.environment
        )
        
        guard let data = try? encoder.encode(manifestData) else {
            throw SecurityError.invalidManifestFormat
        }
        
        // Verify signature
        let isValid = try verifyManifest(data: data, signature: manifest.signature)
        
        guard isValid else {
            SecurityAuditLogger.log(.signatureVerificationFailed)
            throw SecurityError.invalidSignature
        }
        
        print("✅ Manifest signature verified successfully")
        print("   Timestamp: \(manifest.timestamp)")
        print("   Nonce: \(manifest.nonce.prefix(16))...")
        print("   Modules: \(manifest.modules.count)")
    }
    
    // MARK: - Private Helpers
    
    /// Parses PEM-encoded RSA public key and creates SecKey
    private static func parsePublicKey(_ pemString: String) throws -> SecKey {
        // Remove PEM headers and whitespace
        var base64Key = pemString
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Decode base64
        guard let keyData = Data(base64Encoded: base64Key) else {
            throw SecurityError.malformedPublicKey
        }
        
        // Create SecKey attributes
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 2048
        ]
        
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(
            keyData as CFData,
            attributes as CFDictionary,
            &error
        ) else {
            if let error = error {
                let errorDescription = error.takeRetainedValue() as Error
                throw SecurityError.signatureVerificationFailed(errorDescription.localizedDescription)
            }
            throw SecurityError.malformedPublicKey
        }
        
        return secKey
    }
}
