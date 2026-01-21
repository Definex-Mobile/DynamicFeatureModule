//
//  FileLogger.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 20.01.2026.
//

import Foundation

// MARK: - File Logger

final class FileLogger {
    
    private let logFileURL: URL
    private let fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "com.security.filelogger", qos: .utility)
    
    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logsDirectory = documentsURL.appendingPathComponent("SecurityLogs")
        
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let filename = "security-\(dateFormatter.string(from: Date())).log"
        
        self.logFileURL = logsDirectory.appendingPathComponent(filename)
        
        // Create file if doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
        
        self.fileHandle = try? FileHandle(forWritingTo: logFileURL)
    }
    
    func write(_ event: SecurityEvent) {
        queue.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let logLine = "[\(timestamp)] [\(event.severity)] \(event.message)\n"
            
            if let data = logLine.data(using: .utf8) {
                self.fileHandle?.seekToEndOfFile()
                self.fileHandle?.write(data)
            }
        }
    }
    
    deinit {
        try? fileHandle?.close()
    }
}
