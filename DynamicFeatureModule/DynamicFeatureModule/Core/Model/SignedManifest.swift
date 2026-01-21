//
//  SignedManifest.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

// MARK: - Supporting Models

struct SignedManifest: Codable {
    let modules: [ModuleManifestInfo]
    let timestamp: Date
    let nonce: String
    let environment: String
    let signature: String
    
    enum CodingKeys: String, CodingKey {
        case modules, timestamp, nonce, environment, signature
    }
}

struct ManifestData: Codable {
    let modules: [ModuleManifestInfo]
    let timestamp: Date
    let nonce: String
    let environment: String
}

struct ModuleManifestInfo: Codable {
    let id: String
    let name: String
    let version: String
    let checksum: String
    let size: Int64
    let environment: String
}
