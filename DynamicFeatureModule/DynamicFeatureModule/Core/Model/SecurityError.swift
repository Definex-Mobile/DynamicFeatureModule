//
//  SecurityError.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

enum SecurityError: LocalizedError {
    
    // Signature Errors
    case invalidSignature
    case signatureVerificationFailed(String)
    case malformedPublicKey
    case unsupportedSignatureAlgorithm
    
    // Checksum Errors
    case checksumMismatch(expected: String, actual: String)
    case checksumGenerationFailed
    
    // Manifest Errors
    case manifestExpired
    case manifestTooOld
    case manifestTimestampInFuture
    case manifestMissingRequiredFields
    case invalidManifestFormat
    case invalidNonce
    
    // File Security Errors
    case pathTraversalDetected(String)
    case symlinkDetected(String)
    case fileSizeExceeded(size: Int64, limit: Int64)
    case totalSizeExceeded(size: Int64, limit: Int64)
    case fileCountExceeded(count: Int, limit: Int)
    case unsupportedFileType(String)
    case forbiddenFilename(String)
    
    // Environment Errors
    case environmentMismatch(expected: String, actual: String)
    
    // Network Errors
    case certificatePinningFailed
    case untrustedCertificate
    
    // Download Errors
    case tooManyConcurrentDownloads(limit: Int)
    case downloadAlreadyInProgress(moduleId: String)
    case rateLimitExceeded(retryAfter: TimeInterval)
    case downloadQuotaExceeded
    
    // Disk Errors
    case insufficientDiskSpace(required: Int64, available: Int64)
    case diskSpaceCheckFailed
    
    // Quarantine Errors
    case moduleNotInQuarantine(moduleId: String)
    
    // Integrity Errors
    case integrityCheckFailed(reason: String)
    
    // General
    case invalidData
    case installationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidSignature:
            return "Manifest signature is invalid"
        case .signatureVerificationFailed(let reason):
            return "Signature verification failed: \(reason)"
        case .malformedPublicKey:
            return "Public key format is invalid"
        case .unsupportedSignatureAlgorithm:
            return "Signature algorithm not supported"
            
        case .checksumMismatch(let expected, let actual):
            return "Checksum mismatch. Expected: \(expected.prefix(16))..., Got: \(actual.prefix(16))..."
        case .checksumGenerationFailed:
            return "Failed to generate checksum"
            
        case .manifestExpired:
            return "Manifest has expired"
        case .manifestTooOld:
            return "Manifest timestamp is too old (possible replay attack)"
        case .manifestTimestampInFuture:
            return "Manifest timestamp is in the future (clock skew attack)"
        case .manifestMissingRequiredFields:
            return "Manifest is missing required fields"
        case .invalidManifestFormat:
            return "Manifest format is invalid"
        case .invalidNonce:
            return "Invalid nonce in manifest"
            
        case .pathTraversalDetected(let path):
            return "Path traversal detected: \(path)"
        case .symlinkDetected(let path):
            return "Symbolic link detected: \(path)"
        case .fileSizeExceeded(let size, let limit):
            return "File size \(size) bytes exceeds limit \(limit) bytes"
        case .totalSizeExceeded(let size, let limit):
            return "Total size \(size) bytes exceeds limit \(limit) bytes"
        case .fileCountExceeded(let count, let limit):
            return "File count \(count) exceeds limit \(limit)"
        case .unsupportedFileType(let ext):
            return "Unsupported file type: \(ext)"
        case .forbiddenFilename(let name):
            return "Forbidden filename: \(name)"
            
        case .environmentMismatch(let expected, let actual):
            return "Environment mismatch. Expected: \(expected), Got: \(actual)"
            
        case .certificatePinningFailed:
            return "Certificate pinning failed"
        case .untrustedCertificate:
            return "Untrusted certificate detected"
            
        case .tooManyConcurrentDownloads(let limit):
            return "Too many concurrent downloads (limit: \(limit))"
        case .downloadAlreadyInProgress(let moduleId):
            return "Download already in progress: \(moduleId)"
        case .rateLimitExceeded(let retryAfter):
            return "Rate limit exceeded. Retry after \(Int(retryAfter)) seconds"
        case .downloadQuotaExceeded:
            return "Download quota exceeded. Try again later"
            
        case .insufficientDiskSpace(let required, let available):
            return "Insufficient disk space. Need: \(required/1024/1024)MB, Available: \(available/1024/1024)MB"
        case .diskSpaceCheckFailed:
            return "Failed to check disk space"
            
        case .moduleNotInQuarantine(let moduleId):
            return "Module not in quarantine: \(moduleId)"
            
        case .integrityCheckFailed(let reason):
            return "Integrity check failed: \(reason)"
            
        case .invalidData:
            return "Invalid data received"
        case .installationFailed(let reason):
            return "Installation failed: \(reason)"
        }
    }
}
