//
//  ModuleVersion.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

struct ModuleVersion: Codable, Equatable, Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    
    var stringValue: String {
        return "\(major).\(minor).\(patch)"
    }
    
    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    init?(string: String) {
        let cleaned = string.replacingOccurrences(of: "v", with: "")
        let components = cleaned.split(separator: ".").compactMap { Int($0) }
        
        guard components.count == 3 else { return nil }
        
        self.major = components[0]
        self.minor = components[1]
        self.patch = components[2]
    }
    
    // MARK: - Codable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let versionString = try container.decode(String.self)
        
        guard let version = ModuleVersion(string: versionString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid version format: \(versionString). Expected format: '1.2.3' or 'v1.2.3'"
            )
        }
        
        self.major = version.major
        self.minor = version.minor
        self.patch = version.patch
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
    
    // MARK: - Comparable
    static func < (lhs: ModuleVersion, rhs: ModuleVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}
