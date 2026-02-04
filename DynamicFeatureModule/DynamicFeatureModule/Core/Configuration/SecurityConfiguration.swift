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
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs2wiNOOtemnYS3zQVlF4
    Px3ZqdA8weGNrFySKZuR4Onvqh9SOAb2Xd2WVFsTu099Olpiom16u6dyG+3BXbXn
    T4+kmgnfbrrPwaAevhZaWRN0NVaRRBdczfyKD1IxcHMMzUUVQ0hutrGahOAIg3oS
    +oajt9jl5o/9iOfFzZ4SadTvyyFK5JYYVT//1uUBSRQSBifeTdRzSfQeaSs6R6XT
    SKjxs2FBq1YOBaE2tBPjgbeJdgw9+5RR1B4F+2emhFiMY8K4FRiuXdO6e3/RnOi+
    XfmWVhn1tj3lGp0Yd7luxjvUX5vyJZW+AkZ1NDtA6BqGft+gNmSRl1dIl3+suGBR
    LQIDAQAB
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
    
    // MARK: - Network Policies
    
    /// Allow downloads on expensive networks (cellular with data plan warnings)
    static let allowExpensiveNetworkDownloads: Bool = true
    
    /// Allow downloads on constrained networks (Low Data Mode)
    static let allowConstrainedNetworkDownloads: Bool = false
    
    /// Warn user before downloading on cellular
    static let warnOnCellularDownloads: Bool = true
    
    /// Maximum file size for cellular downloads (10 MB)
    static let maxCellularDownloadSize: Int64 = 10 * 1024 * 1024
    
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
