//
//  DownloadStage.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 2.02.2026.
//

import Foundation

enum DownloadStage: Sendable, Equatable {
    case checkingNetwork
    case preflightChecks
    case downloading
    case verifyingChecksum
    case extracting
    case installing
    case integrityCheck
    case completed
    case failed(message: String)
}
