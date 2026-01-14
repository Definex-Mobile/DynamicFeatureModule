//
//  ZipUnarchiver.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation
import Compression

final class ZipUnarchiver {
    
    static let shared = ZipUnarchiver()
    
    private init() {}
    
    func unzip(fileURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        ModuleFileManager.shared.createDirectoryIfNeeded(at: destinationURL)
        
        // Read the zip file
        guard let archive = Archive(url: fileURL, accessMode: .read) else {
            throw NSError(
                domain: "ZipUnarchiver",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to open zip archive"]
            )
        }
        
        for entry in archive {
            let destinationPath = destinationURL.appendingPathComponent(entry.path)
            
            if entry.type == .directory {
                try fileManager.createDirectory(
                    at: destinationPath,
                    withIntermediateDirectories: true
                )
            } else {
                let parentDir = destinationPath.deletingLastPathComponent()
                try fileManager.createDirectory(
                    at: parentDir,
                    withIntermediateDirectories: true
                )
                
                _ = try archive.extract(entry, to: destinationPath)
            }
        }
    }
}

// MARK: - Native Archive Implementation

private class Archive {
    enum EntryType {
        case file
        case directory
    }
    
    struct Entry {
        let path: String
        let type: EntryType
        let data: Data
    }
    
    private let fileURL: URL
    private let entries: [Entry]
    
    init?(url: URL, accessMode: AccessMode) {
        self.fileURL = url
        
        // Read zip file using Foundation
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        // Parse zip entries (simplified implementation)
        self.entries = Archive.parseZipEntries(from: data)
        
        if entries.isEmpty {
            return nil
        }
    }
    
    enum AccessMode {
        case read
        case write
    }
    
    private static func parseZipEntries(from data: Data) -> [Entry] {
        var entries: [Entry] = []
        var offset = 0
        
        while offset < data.count - 30 {
            // Check for local file header signature (0x04034b50)
            let signature = data.subdata(in: offset..<offset+4)
            let signatureValue = signature.withUnsafeBytes { $0.load(as: UInt32.self) }
            
            if signatureValue == 0x04034b50 {
                // Parse entry
                if let entry = parseEntry(from: data, at: offset) {
                    entries.append(entry)
                    offset += entry.data.count + 30 + entry.path.count
                } else {
                    offset += 1
                }
            } else {
                offset += 1
            }
        }
        
        return entries
    }
    
    private static func parseEntry(from data: Data, at offset: Int) -> Entry? {
        guard offset + 30 < data.count else { return nil }
        
        // Read header fields
        let filenameLength = data.subdata(in: offset+26..<offset+28)
            .withUnsafeBytes { $0.load(as: UInt16.self) }
        
        let extraFieldLength = data.subdata(in: offset+28..<offset+30)
            .withUnsafeBytes { $0.load(as: UInt16.self) }
        
        let compressedSize = data.subdata(in: offset+18..<offset+22)
            .withUnsafeBytes { $0.load(as: UInt32.self) }
        
        let headerEnd = offset + 30 + Int(filenameLength) + Int(extraFieldLength)
        guard headerEnd <= data.count else { return nil }
        
        // Get filename
        let filenameData = data.subdata(in: offset+30..<offset+30+Int(filenameLength))
        guard let filename = String(data: filenameData, encoding: .utf8) else {
            return nil
        }
        
        // Determine type
        let type: EntryType = filename.hasSuffix("/") ? .directory : .file
        
        // Get file data
        let dataStart = headerEnd
        let dataEnd = Swift.min(dataStart + Int(compressedSize), data.count)
        let fileData = data.subdata(in: dataStart..<dataEnd)
        
        return Entry(path: filename, type: type, data: fileData)
    }
    
    func extract(_ entry: Entry, to url: URL) throws -> Bool {
        if entry.type == .file {
            try entry.data.write(to: url)
        }
        return true
    }
}

extension Archive: Sequence {
    func makeIterator() -> IndexingIterator<[Entry]> {
        return entries.makeIterator()
    }
}
