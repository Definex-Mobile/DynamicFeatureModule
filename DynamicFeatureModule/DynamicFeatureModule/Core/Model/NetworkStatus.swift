//
//  NetworkStatus.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 2.02.2026.
//


enum NetworkStatus: Sendable, Equatable {
    case unsatisfied
    case requiresConnection
    case satisfied(isExpensive: Bool, isConstrained: Bool)
    
    var isConnected: Bool {
        if case .satisfied = self {
            return true
        }
        return false
    }
}
