//
//  DownloadETAEstimator.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 2.02.2026.
//

import Foundation

struct DownloadETAEstimator {
    static func etaSeconds(bytesReceived: Int64, bytesExpected: Int64?, bps: Double?) -> Double? {
        guard let expected = bytesExpected, expected > 0 else { return nil }
        guard let bps, bps > 0 else { return nil }
        let remaining = Double(expected - bytesReceived)
        guard remaining >= 0 else { return 0 }
        let eta = remaining / bps
        // aşırı büyük ETA’yı bile kontrol edebiliriz. (ör: 24 saat üstünü unknown yapabiliriz.)
        return eta.isFinite && eta < 24 * 3600 ? eta : nil
    }
}
