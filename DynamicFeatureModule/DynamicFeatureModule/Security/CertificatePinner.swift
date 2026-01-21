//
//  CertificatePinner.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation
import CommonCrypto

protocol CertificatePinnerProtocol {
    func validate(challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

final class CertificatePinner: NSObject, CertificatePinnerProtocol {
    
    // SHA-256 hashes of trusted certificates (public key hashes)
    // Generate with: openssl x509 -in cert.pem -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
    private static let trustedPublicKeyHashes: Set<String> = [
        // Production certificate
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        // Backup certificate
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
    ]
    
    /// Validates server certificate during TLS handshake
    func validate(challenge: URLAuthenticationChallenge,
                  completionHandler completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Only validate server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // For localhost development, allow untrusted certificates
        if SecurityConfiguration.allowInsecureLocalhost,
           challenge.protectionSpace.host == "localhost" || challenge.protectionSpace.host == "127.0.0.1" {
            print("⚠️  Allowing localhost without pinning (development mode)")
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }
        
        // Extract server certificate
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            SecurityAuditLogger.log(.certificatePinningFailed(reason: "No certificate found"))
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get public key from certificate
        guard let serverPublicKey = SecCertificateCopyKey(serverCertificate) else {
            SecurityAuditLogger.log(.certificatePinningFailed(reason: "Could not extract public key"))
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Convert public key to data
        guard let publicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            SecurityAuditLogger.log(.certificatePinningFailed(reason: "Could not serialize public key"))
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Hash the public key
        let publicKeyHash = sha256Base64(data: publicKeyData)
        
        // Check if hash matches trusted certificates
        if CertificatePinner.trustedPublicKeyHashes.contains(publicKeyHash) {
            print("✅ Certificate pinning: PASSED")
            SecurityAuditLogger.log(.certificatePinningSuccess(hash: publicKeyHash))
            
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            print("🚨 Certificate pinning: FAILED")
            print("   Server public key hash: \(publicKeyHash)")
            
            SecurityAuditLogger.log(.certificatePinningFailed(reason: "Hash mismatch: \(publicKeyHash)"))
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    // MARK: - Private Helpers
    
    private func sha256Base64(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
}
