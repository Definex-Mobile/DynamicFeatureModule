//
//  NetworkMonitor.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 2.02.2026.
//

import Network
import Foundation

protocol NetworkMonitoring: Sendable {
    var current: NetworkStatus { get }
    var connectionType: ConnectionType { get }
    var isExpensiveConnection: Bool { get }
    var isConstrainedConnection: Bool { get }
    
    func start()
    func stop()
    func observe(_ handler: @escaping @Sendable (NetworkStatus) -> Void)
}

final class NetworkMonitor: NetworkMonitoring {
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "dfm.network.monitor")
    private var handlers: [(@Sendable (NetworkStatus) -> Void)] = []
    private let lock = NSLock()
    
    private(set) var current: NetworkStatus = .satisfied(isExpensive: false, isConstrained: false)
    
    init() {}
    
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let status: NetworkStatus
            switch path.status {
            case .satisfied:
                status = .satisfied(isExpensive: path.isExpensive, isConstrained: path.isConstrained)
            case .unsatisfied:
                status = .unsatisfied
            case .requiresConnection:
                status = .requiresConnection
            @unknown default:
                status = .unsatisfied
            }
            self.lock.lock()
            self.current = status
            let localHandlers = self.handlers
            self.lock.unlock()
            localHandlers.forEach { $0(status) }
        }
        monitor.start(queue: queue)
    }
    
    func stop() {
        monitor.cancel()
    }
    
    func observe(_ handler: @escaping @Sendable (NetworkStatus) -> Void) {
        lock.lock()
        handlers.append(handler)
        let now = current
        lock.unlock()
        handler(now)
    }
    
    // MARK: - Network Type Detection
    
    var connectionType: ConnectionType {
        lock.lock()
        defer { lock.unlock() }
        return detectConnectionType()
    }
    
    private func detectConnectionType() -> ConnectionType {
        guard case .satisfied = current else {
            return .none
        }
        
        let path = monitor.currentPath
        
        // Check WiFi first
        if path.usesInterfaceType(.wifi) {
            return .wifi
        }
        
        // Check Cellular
        if path.usesInterfaceType(.cellular) {
            return .cellular
        }
        
        // Check Wired (Ethernet) - rare on iOS but possible with adapters
        if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        }
        
        // Other types (e.g., loopback)
        if path.usesInterfaceType(.loopback) {
            return .loopback
        }
        
        return .other
    }
    
    var isExpensiveConnection: Bool {
        lock.lock()
        defer { lock.unlock() }
        if case .satisfied(let isExpensive, _) = current {
            return isExpensive
        }
        return false
    }
    
    var isConstrainedConnection: Bool {
        lock.lock()
        defer { lock.unlock() }
        if case .satisfied(_, let isConstrained) = current {
            return isConstrained
        }
        return false
    }
}
