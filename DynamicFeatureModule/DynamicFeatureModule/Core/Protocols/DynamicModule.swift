//
//  DynamicModule.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

protocol DynamicModule {
    var moduleId: String { get }
    var version: ModuleVersion { get }
    var contentPath: URL { get }
    
    func load() throws
    func unload()
}

typealias DownloadProgressHandler = (Double) -> Void

typealias DownloadCompletionHandler = (Result<URL, ModuleError>) -> Void
