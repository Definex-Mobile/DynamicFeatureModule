//
//  NetworkError.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 4.02.2026.
//

import Foundation

enum NetworkError: Error, Sendable {
    case unknown
    case noInternet
    case networkUnsatisfied
    case networkConstrained
    case networkExpensive
    case cellularDownloadTooLarge(fileSize: Int64, maxSize: Int64)
    case requiresConnection
    case networkNotAllowed(NetworkRestriction)
    case downloadFailed(reason: String)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection available."
        
        case .networkUnsatisfied:
            return "Network connection is unsatisfied."

        case .networkConstrained:
            return "Download not allowed on Low Data Mode network."
        
        case .networkExpensive:
            return "Download not allowed on cellular network."
        
        case .cellularDownloadTooLarge(let fileSize, let maxSize):
            let fileMB = Double(fileSize) / 1024 / 1024
            let maxMB = Double(maxSize) / 1024 / 1024
            return String(format: "File size (%.1f MB) exceeds cellular download limit (%.1f MB). Please connect to WiFi.", fileMB, maxMB)

        case .requiresConnection:
            return "Network connection is required."

        case .networkNotAllowed(let restriction):
            switch restriction {
            case .expensiveNotAllowed:
                return "Cellular network is not allowed for this download."
            case .constrainedNotAllowed:
                return "Low Data Mode is enabled. This download requires full network access."
            }

        case .downloadFailed(let reason):
            return "Download failed: \(reason)"

        case .unknown:
            return "An unknown error occurred."
        }
    }
}

enum NetworkRestriction: Sendable {
    case expensiveNotAllowed      // Cellular
    case constrainedNotAllowed    // Low Data Mode
}
