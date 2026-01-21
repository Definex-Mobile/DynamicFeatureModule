//
//  SecurityConfiguration.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

struct SecurityConfiguration {
    
    // MARK: - Signature Verification
    
    /// RSA Public Key (PEM format) for manifest signature verification
    /// This should be the public key corresponding to the backend's private key
    static let manifestPublicKey = """
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AbIIBCgKsAQEA2Z3qX0LW1YsyV8cMqHqm
    P9xHFq7KYJ+vE5J9XxYZH7NkW2dQ8sL1mR3pK9xT7sE6WqJ8vL2nK9xY8sM1pL2n
    K9xY8sM1pL2nK9xY8sM1aL2nK9xY8sM1pl2nK9xY8sM1pL2nK9xY8sM1pL2nK9xY
    8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL3nK4xY8sM1
    pL2nK9xk8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2n
    K9xY8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2nK9xY
    8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2nK9xY8sM1pL2nK9xYCAwEAAQ==
    -----END PUBLIC KEY-----
    """
    
    // MARK: - File Size Limits
    
    /// Maximum download size in bytes (50 MB)
    static let maxDownloadSize: Int64 = 50 * 1024 * 1024
    
    /// Maximum uncompressed size in bytes (100 MB)
    static let maxUncompressedSize: Int64 = 100 * 1024 * 1024
    
    /// Maximum individual file size in bytes (20 MB)
    static let maxIndividualFileSize: Int64 = 20 * 1024 * 1024
    
    /// Maximum number of files in a module
    static let maxFileCount: Int = 500
    
    // MARK: - Timeout & Rate Limiting
    
    /// Download timeout in seconds
    static let downloadTimeout: TimeInterval = 60
    
    /// Minimum time between download attempts (seconds)
    static let downloadCooldown: TimeInterval = 5
    
    /// Maximum manifest age (seconds) - prevents replay attacks
    static let maxManifestAge: TimeInterval = 300 // 5 minutes
    
    // MARK: - Path Validation
    
    /// Allowed file extensions
    static let allowedExtensions: Set<String> = [
        "html", "css", "js", "json", "png", "jpg", "jpeg", "svg", "woff", "woff2", "ttf"
    ]
    
    /// Forbidden filename patterns
    static let forbiddenPatterns: [String] = [
        "..", "~", "__MACOSX", ".DS_Store", ".git", ".svn"
    ]
    
    // MARK: - Environment Validation
    
    /// Enforce environment matching (dev module can't run in production)
    static let enforceEnvironmentMatch: Bool = true
    
    static let checksumAlgorithm: ChecksumAlgorithm = .sha256
    
    // MARK: - Download Management
    
    /// Maximum concurrent downloads
    static let maxConcurrentDownloads: Int = 3
    
    /// Maximum downloads per hour (DoS prevention)
    static let maxDownloadsPerHour: Int = 20
    
    // MARK: - Network Security
    
    /// Allow localhost without certificate pinning (development only)
    static let allowInsecureLocalhost: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Integrity Checks
    
    /// Perform periodic integrity checks
    static let enablePeriodicIntegrityChecks: Bool = true
    
    /// Integrity check interval (seconds)
    static let integrityCheckInterval: TimeInterval = 86400 // 24 hours
    
    // MARK: - Checksum Algorithm
    
    enum ChecksumAlgorithm: String {
        case sha256 = "SHA-256"
        case sha512 = "SHA-512"
    }
}
