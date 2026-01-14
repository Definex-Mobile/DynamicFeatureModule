//
//  ModuleMetadata.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

struct ModuleMetadata: Codable {
    let id: String
    let name: String
    let version: ModuleVersion
    let downloadURL: URL
    let checksum: String
    let size: Int64?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case version
        case downloadURL = "downloadUrl"
        case checksum
        case size
    }
}

struct ModulesResponse: Codable {
    let modules: [ModuleMetadata]
}
