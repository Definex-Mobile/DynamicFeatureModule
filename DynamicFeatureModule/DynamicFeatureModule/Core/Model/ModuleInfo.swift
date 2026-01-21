//
//  ModuleInfo.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

struct ModuleInfo: Codable, Identifiable {
    let id: String
    let name: String
    let version: String
    let checksum: String
    let size: Int64
    let environment: String
    let downloadURL: String
    let metadata: ModuleMetadata?
    
    struct ModuleMetadata: Codable {
        let description: String?
        let author: String?
        let releaseDate: Date?
        let minAppVersion: String?
    }
}

struct ModuleListResponse: Codable {
    let manifest: SignedManifest
    let serverTime: Date
    
    enum CodingKeys: String, CodingKey {
        case manifest
        case serverTime = "server_time"
    }
}
