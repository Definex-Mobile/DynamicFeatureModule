//
//  SafeUnzipper.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation
import ZIPFoundation

struct SafeUnzipper {
    
    private let baseDirectory: URL
    
    init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }
    
    /// Safely extracts ZIP file with security checks
    func extract(zipURL: URL, to destinationURL: URL) throws {
        print("🔓 Starting safe extraction...")
        
        // Pre-validation: Check zip file size
        let attributes = try FileManager.default.attributesOfItem(atPath: zipURL.path)
        guard let fileSize = attributes[.size] as? Int64 else {
            throw SecurityError.invalidData
        }
        
        guard fileSize <= SecurityConfiguration.maxDownloadSize else {
            throw SecurityError.fileSizeExceeded(size: fileSize, limit: SecurityConfiguration.maxDownloadSize)
        }
        
        // Open ZIP archive
        guard let archive = Archive(url: zipURL, accessMode: .read) else {
            throw SecurityError.invalidData
        }
        
        // Count entries manually
        var entryCount = 0
        var entries: [Entry] = []
        for entry in archive {
            entries.append(entry)
            entryCount += 1
        }
        
        // Validate total file count
        guard entryCount <= SecurityConfiguration.maxFileCount else {
            throw SecurityError.fileCountExceeded(count: entryCount, limit: SecurityConfiguration.maxFileCount)
        }
        
        var totalUncompressedSize: Int64 = 0
        
        // First pass: Validate all entries
        for entry in entries {
            try validateEntry(entry, totalSize: &totalUncompressedSize)
        }
        
        // Check total uncompressed size
        guard totalUncompressedSize <= SecurityConfiguration.maxUncompressedSize else {
            throw SecurityError.totalSizeExceeded(
                size: totalUncompressedSize,
                limit: SecurityConfiguration.maxUncompressedSize
            )
        }
        
        print("✅ Pre-validation passed")
        print("   Files: \(entryCount)")
        print("   Total size: \(totalUncompressedSize) bytes")
        
        // Second pass: Extract files
        for entry in entries {
            try extractEntry(entry, from: archive, to: destinationURL)
        }
        
        print("✅ Safe extraction completed")
    }
    
    // MARK: - Private Helpers
    
    private func validateEntry(_ entry: Entry, totalSize: inout Int64) throws {
        let entryPath = entry.path
        
        // 1. Check for path traversal
        if entryPath.contains("..") {
            throw SecurityError.pathTraversalDetected(entryPath)
        }
        
        // 2. Check for forbidden patterns
        for pattern in SecurityConfiguration.forbiddenPatterns {
            if entryPath.contains(pattern) {
                throw SecurityError.forbiddenFilename(entryPath)
            }
        }
        
        // 3. Check for hidden files (except in subdirectories)
        let components = entryPath.split(separator: "/")
        if let fileName = components.last, fileName.hasPrefix(".") {
            throw SecurityError.forbiddenFilename(String(fileName))
        }
        
        // 4. Validate file extension
        if entry.type == .file {
            let ext = (entryPath as NSString).pathExtension.lowercased()
            if !ext.isEmpty && !SecurityConfiguration.allowedExtensions.contains(ext) {
                throw SecurityError.unsupportedFileType(ext)
            }
        }
        
        // 5. Check individual file size
        let uncompressedSize = Int64(entry.uncompressedSize)
        guard uncompressedSize <= SecurityConfiguration.maxIndividualFileSize else {
            throw SecurityError.fileSizeExceeded(
                size: uncompressedSize,
                limit: SecurityConfiguration.maxIndividualFileSize
            )
        }
        
        totalSize += uncompressedSize
    }
    
    private func extractEntry(_ entry: Entry, from archive: Archive, to destinationURL: URL) throws {
        let destinationPath = destinationURL.appendingPathComponent(entry.path)
        
        // Normalize and validate final path
        let normalizedDestination = destinationPath.standardized
        let normalizedBase = destinationURL.standardized
        
        // Ensure destination is within base directory (prevent zip slip)
        guard normalizedDestination.path.hasPrefix(normalizedBase.path) else {
            throw SecurityError.pathTraversalDetected(entry.path)
        }
        
        // Create parent directory if needed
        let parentDirectory = normalizedDestination.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parentDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Extract entry
        _ = try archive.extract(entry, to: normalizedDestination)
        
        // Post-extraction validation: Check for symlinks
        let attributes = try FileManager.default.attributesOfItem(atPath: normalizedDestination.path)
        if attributes[.type] as? FileAttributeType == .typeSymbolicLink {
            // Remove symlink and throw error
            try? FileManager.default.removeItem(at: normalizedDestination)
            throw SecurityError.symlinkDetected(entry.path)
        }
    }
}
