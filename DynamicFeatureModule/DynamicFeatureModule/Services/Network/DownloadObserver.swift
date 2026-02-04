//
//  DownloadObserver.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 2.02.2026.
//

import Foundation

protocol DownloadObserving: Sendable {
    func emit(stage: DownloadStage)
}

final class DownloadObserver: DownloadObserving {
    private let lock = NSLock()
    private var handlers: [(@Sendable (DownloadStage) -> Void)] = []
    
    init() {}
    
    func subscribe(_ handler: @escaping @Sendable (DownloadStage) -> Void) {
        lock.lock()
        handlers.append(handler)
        lock.unlock()
    }
    
    func emit(stage: DownloadStage) {
        lock.lock()
        let local = handlers
        lock.unlock()
        local.forEach { $0(stage) }
    }
}
