//
//  ViewController+Extension.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 4.02.2026.
//

import Foundation


extension ViewController {
    // MARK: - Formatting

    func formatSpeed(_ bps: Double?) -> String {
        guard let bps, bps.isFinite, bps >= 0 else { return "— B/s" }
        if bps < 1 { return "0 B/s" }

        let kb = bps / 1024
        let mb = kb / 1024
        if mb >= 1 { return String(format: "%.2f MB/s", mb) }
        if kb >= 1 { return String(format: "%.0f KB/s", kb) }
        return String(format: "%.0f B/s", bps)
    }

    func formatETA(_ seconds: Double?) -> String {
        guard let seconds, seconds.isFinite, seconds >= 0 else { return "—" }

        let total = Int(seconds.rounded())
        if total <= 0 { return "00:00" }

        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        if bytes < 1024 {
            return "\(bytes) bytes"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.2f MB", Double(bytes) / 1024 / 1024)
        }
    }

    func prettyError(_ error: Error) -> String {
        let text = error.localizedDescription
        if text.lowercased().contains("cancel") { return "Canceled" }
        if text.lowercased().contains("offline") || text.lowercased().contains("internet") { return "No Internet" }
        if text.contains("cellular") { return "Cellular limit exceeded" }
        if text.contains("constrained") { return "Low Data Mode active" }
        return text
    }
    
    func formatJSON(_ json: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }
}
