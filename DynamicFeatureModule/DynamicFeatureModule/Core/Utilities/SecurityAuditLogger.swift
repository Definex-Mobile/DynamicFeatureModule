//
//  SecurityAuditLogger.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation
import os.log

enum SecurityEvent {
    // Signature Events
    case signatureVerified(algorithm: String)
    case signatureVerificationFailed
    case invalidSignatureDetected
    
    // Checksum Events
    case checksumVerified(algorithm: String, size: Int64)
    case checksumMismatch(expected: String, actual: String)
    
    // Certificate Pinning Events
    case certificatePinningSuccess(hash: String)
    case certificatePinningFailed(reason: String)
    
    // Extraction Events
    case pathTraversalAttempt(path: String)
    case symlinkDetected(path: String)
    case forbiddenFileDetected(name: String)
    case zipBombDetected(size: Int64)
    
    // Installation Events
    case installationSuccess(module: String, version: String)
    case installationFailed(module: String, error: String)
    case rollbackPerformed(module: String)
    
    // Network Events
    case replayAttemptDetected(age: TimeInterval)
    case rateLimitExceeded(cooldownRemaining: TimeInterval)
    case manifestTimestampInFuture
    
    // Quarantine Events
    case moduleQuarantined(module: String, reason: String)
    case quarantineReleased(module: String)
    
    // Integrity Events
    case integrityCheckPassed(module: String)
    case integrityCheckFailed(module: String, reason: String)
    
    // Disk Events
    case insufficientDiskSpace(required: Int64, available: Int64)
    
    var severity: OSLogType {
        switch self {
        case .signatureVerified, .checksumVerified, .certificatePinningSuccess,
             .installationSuccess, .integrityCheckPassed, .quarantineReleased:
            return .info
            
        case .rateLimitExceeded, .insufficientDiskSpace:
            return .default
            
        case .installationFailed, .rollbackPerformed, .integrityCheckFailed,
             .checksumMismatch, .zipBombDetected:
            return .error
            
        case .signatureVerificationFailed, .invalidSignatureDetected,
             .certificatePinningFailed, .pathTraversalAttempt, .symlinkDetected,
             .forbiddenFileDetected, .replayAttemptDetected, .manifestTimestampInFuture,
             .moduleQuarantined:
            return .fault
        }
    }
    
    var message: String {
        switch self {
        case .signatureVerified(let algorithm):
            return "✅ Signature verified using \(algorithm)"
        case .signatureVerificationFailed:
            return "🚨 Signature verification FAILED"
        case .invalidSignatureDetected:
            return "🚨 Invalid signature detected"
            
        case .checksumVerified(let algorithm, let size):
            return "✅ Checksum verified (\(algorithm)) - \(size) bytes"
        case .checksumMismatch(let expected, let actual):
            return "🚨 Checksum mismatch! Expected: \(expected.prefix(16))... Got: \(actual.prefix(16))..."
            
        case .certificatePinningSuccess(let hash):
            return "✅ Certificate pinning passed - Hash: \(hash.prefix(16))..."
        case .certificatePinningFailed(let reason):
            return "🚨 Certificate pinning FAILED: \(reason)"
            
        case .pathTraversalAttempt(let path):
            return "🚨 PATH TRAVERSAL ATTEMPT: \(path)"
        case .symlinkDetected(let path):
            return "🚨 SYMLINK DETECTED: \(path)"
        case .forbiddenFileDetected(let name):
            return "🚨 Forbidden file detected: \(name)"
        case .zipBombDetected(let size):
            return "🚨 ZIP BOMB detected: \(size) bytes"
            
        case .installationSuccess(let module, let version):
            return "✅ Installation success: \(module) v\(version)"
        case .installationFailed(let module, let error):
            return "❌ Installation failed: \(module) - \(error)"
        case .rollbackPerformed(let module):
            return "↩️  Rollback performed: \(module)"
            
        case .replayAttemptDetected(let age):
            return "🚨 REPLAY ATTACK detected - Manifest age: \(Int(age))s"
        case .rateLimitExceeded(let remaining):
            return "⏳ Rate limit exceeded - Wait \(Int(remaining))s"
        case .manifestTimestampInFuture:
            return "🚨 Manifest timestamp in FUTURE (clock skew attack?)"
            
        case .moduleQuarantined(let module, let reason):
            return "🔒 Module quarantined: \(module) - \(reason)"
        case .quarantineReleased(let module):
            return "🔓 Quarantine released: \(module)"
            
        case .integrityCheckPassed(let module):
            return "✅ Integrity check passed: \(module)"
        case .integrityCheckFailed(let module, let reason):
            return "🚨 INTEGRITY CHECK FAILED: \(module) - \(reason)"
            
        case .insufficientDiskSpace(let required, let available):
            return "💾 Insufficient disk space - Need: \(required/1024/1024)MB, Available: \(available/1024/1024)MB"
        }
    }
}

struct SecurityAuditLogger {
    
    private static let log = OSLog(subsystem: "com.dynamicmodule.security", category: "SecurityAudit")
    private static let fileLogger = FileLogger()
    
    /// Logs security event to system log and file
    static func log(_ event: SecurityEvent) {
        // Log to system (Console.app)
        os_log("%{public}@", log: log, type: event.severity, event.message)
        
        // Log to file for persistence
        fileLogger.write(event)
        
        // Print to console for development
        print("[SECURITY] \(event.message)")
        
        // In production: Send critical events to analytics/crash reporting
        if event.severity == .fault {
            sendToAnalytics(event)
        }
    }
    
    private static func sendToAnalytics(_ event: SecurityEvent) {
        // Integrate with Firebase Crashlytics, Sentry, etc.
        // Example: Crashlytics.crashlytics().record(error: SecurityError.auditEvent(event))
    }
}
