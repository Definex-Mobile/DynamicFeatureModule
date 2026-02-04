//
//  DownloadThroughputEstimator.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 2.02.2026.
//

import Foundation
import QuartzCore

actor DownloadThroughputEstimator {
    static var lastTime: CFTimeInterval?
    static var lastBytes: Int64?
    
    private var smoothedBps: Double = 0
    private var samples: Int = 0
    
    private let alpha: Double
    private let minSamplesForTrust: Int
    private let minDt: Double
    
    init(alpha: Double = 0.25, minSamplesForTrust: Int = 2, minDt: Double = 0.06) {
        self.alpha = alpha
        self.minSamplesForTrust = minSamplesForTrust
        self.minDt = minDt
    }
    
    func reset() {
       // DownloadThroughputEstimator.lastTime = nil
       // DownloadThroughputEstimator.lastBytes = nil
       // smoothedBps = 0
       // samples = 0
    }
    
    func update(totalBytes: Int64) -> Double? {
        let now = CACurrentMediaTime()
        // first sample: prime state
        guard let lt = DownloadThroughputEstimator.lastTime, let lb = DownloadThroughputEstimator.lastBytes else {
            DownloadThroughputEstimator.lastTime = now
            DownloadThroughputEstimator.lastBytes = totalBytes
            return nil
        }
        
        let dt = now - lt
        
        let db = Double(totalBytes - lb)
        guard db >= 0 else { return nil }
        
        let instant = db / dt
        
        // Now commit sample point
        DownloadThroughputEstimator.lastTime = now
        DownloadThroughputEstimator.lastBytes = totalBytes
        
        smoothedBps = (smoothedBps == 0) ? instant : (alpha * instant + (1 - alpha) * smoothedBps)
        samples += 1
        
        return (samples >= minSamplesForTrust) ? smoothedBps : nil
    }
}

