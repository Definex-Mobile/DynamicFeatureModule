//
//  APIService.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation
import Network

// MARK: - APIServiceProtocol

protocol APIServiceProtocol {
    func fetchAvailableModules() async throws -> [ModuleInfo]
    func downloadModule(moduleInfo: ModuleInfo,
                        progressHandler: @escaping (DownloadProgress) -> Void) async throws -> URL
}

// MARK: - APIService

final class APIService: NSObject, APIServiceProtocol {

    private let baseURL: String
    private var session: URLSession

    private let downloadCoordinator: DownloadCoordinatorProtocol
    private let quarantineManager: QuarantineManagerProtocol
    private let certificatePinner: CertificatePinnerProtocol
    private let diskSpaceManager: DiskSpaceManagerProtocol
    private let networkMonitor: NetworkMonitoring
    private let downloadObserver: DownloadObserving?

    // Active download state
    private var activeDownloadTask: URLSessionDownloadTask?
    private var activeContinuation: CheckedContinuation<URL, Error>?
    private var activeTempURL: URL?
    private var activeProgressHandler: ((DownloadProgress) -> Void)?
    private var activeAttemptId: UUID?
    private var activeModuleInfo: ModuleInfo?

    // Speed/ETA estimator
    private let speedEstimator: DownloadThroughputEstimator

    init(downloadCoordinator: DownloadCoordinatorProtocol,
         quarantineManager: QuarantineManagerProtocol,
         certificatePinner: CertificatePinnerProtocol,
         diskSpaceManager: DiskSpaceManagerProtocol,
         networkMonitor: NetworkMonitoring,
         downloadObserver: DownloadObserving? = nil,
         speedEstimator: DownloadThroughputEstimator) {

        self.downloadCoordinator = downloadCoordinator
        self.quarantineManager = quarantineManager
        self.certificatePinner = certificatePinner
        self.diskSpaceManager = diskSpaceManager
        self.networkMonitor = networkMonitor
        self.downloadObserver = downloadObserver
        self.speedEstimator = speedEstimator
        self.baseURL = ConfigurationManager.shared.backendURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = SecurityConfiguration.downloadTimeout
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        self.session = URLSession(configuration: config)
        super.init()
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        networkMonitor.start()
        observeNetworkChanges()
    }

    deinit {
        networkMonitor.stop()
    }

    // MARK: - Network monitoring

    private func observeNetworkChanges() {
        networkMonitor.observe { [weak self] status in
            guard let self else { return }
            
            // If connection drops mid-download -> cancel task
            if !status.isConnected, let task = self.activeDownloadTask {
                print("⚠️ Network disconnected, cancelling active download")
                task.cancel()
            }
        }
    }

    private func validateNetworkForDownload(fileSize: Int64) throws {
        let status = networkMonitor.current
        
        guard status.isConnected else {
            throw NetworkError.noInternet
        }
        
        // Check constrained mode (Low Data Mode)
        if networkMonitor.isConstrainedConnection {
            if !SecurityConfiguration.allowConstrainedNetworkDownloads {
                throw NetworkError.networkConstrained
            }
        }
        
        // Check expensive networks (cellular)
        if networkMonitor.isExpensiveConnection {
            if !SecurityConfiguration.allowExpensiveNetworkDownloads {
                throw NetworkError.networkExpensive
            }
        }
        
        // Check cellular-specific limits
        let connectionType = networkMonitor.connectionType
        if connectionType == .cellular {
            let maxCellularSize = SecurityConfiguration.maxCellularDownloadSize
            if fileSize > maxCellularSize {
                throw NetworkError.cellularDownloadTooLarge(
                    fileSize: fileSize,
                    maxSize: maxCellularSize
                )
            }
        }
        
        logNetworkInfo()
    }
    
    private func logNetworkInfo() {
        let type = networkMonitor.connectionType
        let expensive = networkMonitor.isExpensiveConnection
        let constrained = networkMonitor.isConstrainedConnection
        
        print("📶 Network Status:")
        print("   Type: \(type.rawValue)")
        print("   Expensive: \(expensive ? "Yes" : "No")")
        print("   Constrained: \(constrained ? "Yes (Low Data Mode)" : "No")")
    }

    // MARK: - Fetch manifest

    func fetchAvailableModules() async throws -> [ModuleInfo] {
        print("🌐 Fetching modules from backend...")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        guard networkMonitor.current.isConnected else {
            throw NetworkError.noInternet
        }

        let url = URL(string: "\(baseURL)/api/modules")!
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Raw JSON Response:")
            print(jsonString)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }

        let decoder = JSONDecoder()

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = formatter.date(from: dateString) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) { return date }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }

        do {
            let moduleResponse = try decoder.decode(ModuleListResponse.self, from: data)

            print("📋 Manifest received")
            print("   Timestamp: \(moduleResponse.manifest.timestamp)")
            print("   Environment: \(moduleResponse.manifest.environment)")
            print("   Modules: \(moduleResponse.manifest.modules.count)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            print("🔐 Verifying manifest signature...")
            try SignatureVerifier.verifySignedManifest(moduleResponse.manifest)

            let currentEnv = ConfigurationManager.shared.environment.rawValue
            if SecurityConfiguration.enforceEnvironmentMatch {
                guard moduleResponse.manifest.environment == currentEnv else {
                    throw SecurityError.environmentMismatch(expected: currentEnv, actual: moduleResponse.manifest.environment)
                }
                print("✅ Environment validated: \(currentEnv)")
            }

            let modules = moduleResponse.manifest.modules.map { manifestInfo in
                ModuleInfo(
                    id: manifestInfo.id,
                    name: manifestInfo.name,
                    version: manifestInfo.version,
                    checksum: manifestInfo.checksum,
                    size: manifestInfo.size,
                    environment: manifestInfo.environment,
                    downloadURL: "\(baseURL)/api/modules/\(manifestInfo.id)/download",
                    metadata: nil
                )
            }

            print("✅ Fetched \(modules.count) verified modules")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return modules

        } catch {
            print("❌ Decoding/Validation Error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Download pipeline

    func downloadModule(
        moduleInfo: ModuleInfo,
        progressHandler: @escaping (DownloadProgress) -> Void
    ) async throws -> URL {

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔒 STARTING FULL SECURITY PIPELINE")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📦 Module: \(moduleInfo.name) v\(moduleInfo.version)")
        print("📏 Size: \(moduleInfo.size / 1024 / 1024) MB")
        print("🔑 Checksum: \(moduleInfo.checksum.prefix(16))...")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        downloadObserver?.emit(stage: .checkingNetwork)
        print("\n[STAGE 1] NETWORK & PRE-FLIGHT CHECKS")

        // (A) Network validation with WiFi/Cellular awareness
        do {
            try validateNetworkForDownload(fileSize: moduleInfo.size)
            print("  ✅ Network validation: PASS")
        } catch {
            print("  ❌ Network validation: FAILED - \(error.localizedDescription)")
            downloadObserver?.emit(stage: .failed(message: error.localizedDescription))
            throw error
        }

        downloadObserver?.emit(stage: .preflightChecks)

        // (B) Download coordinator slot reservation
        let attemptId: UUID
        do {
            print("  ⏳ Checking download coordinator...")
            attemptId = try await downloadCoordinator.canStartDownload(moduleId: moduleInfo.id)
            print("  ✅ Download coordinator: PASS (Attempt ID: \(attemptId.uuidString.prefix(8)))")
        } catch {
            print("  ❌ Download coordinator: FAILED - \(error.localizedDescription)")
            downloadObserver?.emit(stage: .failed(message: error.localizedDescription))
            throw error
        }

        // (C) Disk space check
        do {
            print("  💾 Checking disk space...")
            try diskSpaceManager.checkAvailableSpace(required: moduleInfo.size)
            print("  ✅ Disk space: PASS")
        } catch {
            await downloadCoordinator.completeDownload(
                moduleId: moduleInfo.id,
                attemptId: attemptId,
                reason: .unknown,
                bytesDownloaded: 0,
                expectedBytes: moduleInfo.size
            )
            downloadObserver?.emit(stage: .failed(message: error.localizedDescription))
            throw error
        }

        // (D) Environment match
        if SecurityConfiguration.enforceEnvironmentMatch {
            let currentEnv = ConfigurationManager.shared.environment.rawValue
            guard moduleInfo.environment == currentEnv else {
                let error = SecurityError.environmentMismatch(expected: currentEnv, actual: moduleInfo.environment)
                await downloadCoordinator.completeDownload(
                    moduleId: moduleInfo.id,
                    attemptId: attemptId,
                    reason: .unknown,
                    bytesDownloaded: 0,
                    expectedBytes: moduleInfo.size
                )
                downloadObserver?.emit(stage: .failed(message: error.localizedDescription))
                throw error
            }
            print("  ✅ Environment: PASS")
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        downloadObserver?.emit(stage: .downloading)
        print("\n[STAGE 2] SECURE DOWNLOAD")
        print("  📥 Downloading from: \(moduleInfo.downloadURL)")

        let zipURL: URL
        do {
            zipURL = try await downloadFileWithProgress(
                moduleInfo: moduleInfo,
                attemptId: attemptId,
                progressHandler: progressHandler
            )
            print("  ✅ Download complete: \(zipURL.path)")
        } catch let error as NSError {
            let reason = mapErrorToDownloadEndReason(error)
            await downloadCoordinator.completeDownload(
                moduleId: moduleInfo.id,
                attemptId: attemptId,
                reason: reason,
                bytesDownloaded: 0,
                expectedBytes: moduleInfo.size
            )
            downloadObserver?.emit(stage: .failed(message: error.localizedDescription))
            throw error
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        downloadObserver?.emit(stage: .verifyingChecksum)
        print("\n[STAGE 3] CHECKSUM VERIFICATION")
        print("  🔍 Algorithm: \(SecurityConfiguration.checksumAlgorithm.rawValue)")

        do {
            try ChecksumValidator.validate(
                fileURL: zipURL,
                expectedChecksum: moduleInfo.checksum
            )

            let fileSize = (try? FileManager.default.attributesOfItem(atPath: zipURL.path)[.size] as? Int64) ?? 0
            SecurityAuditLogger.log(.checksumVerified(
                algorithm: SecurityConfiguration.checksumAlgorithm.rawValue,
                size: fileSize
            ))

            print("  ✅ Checksum: VERIFIED")

        } catch {
            try? await quarantineManager.quarantine(
                moduleId: moduleInfo.id,
                path: zipURL,
                reason: "Checksum mismatch"
            )

            await downloadCoordinator.completeDownload(
                moduleId: moduleInfo.id,
                attemptId: attemptId,
                reason: .checksumMismatch,
                bytesDownloaded: moduleInfo.size,
                expectedBytes: moduleInfo.size
            )

            downloadObserver?.emit(stage: .failed(message: "Checksum verification failed"))
            throw error
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        downloadObserver?.emit(stage: .extracting)
        print("\n[STAGE 4] SAFE EXTRACTION")
        let stagingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("UnzipStaging")
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: stagingURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        do {
            let unzipper = SafeUnzipper(baseDirectory: stagingURL)
            try unzipper.extract(zipURL: zipURL, to: stagingURL)
            print("  ✅ Safe extraction: COMPLETE")

        } catch let error as SecurityError {
            try? await quarantineManager.quarantine(
                moduleId: moduleInfo.id,
                path: zipURL,
                reason: error.localizedDescription
            )

            try? FileManager.default.removeItem(at: stagingURL)

            await downloadCoordinator.completeDownload(
                moduleId: moduleInfo.id,
                attemptId: attemptId,
                reason: .unknown,
                bytesDownloaded: moduleInfo.size,
                expectedBytes: moduleInfo.size
            )

            downloadObserver?.emit(stage: .failed(message: error.localizedDescription))
            throw error
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        downloadObserver?.emit(stage: .installing)
        print("\n[STAGE 5] ATOMIC INSTALLATION")

        let installer = AtomicInstaller()
        let finalURL: URL

        do {
            finalURL = try installer.install(
                sourceURL: stagingURL,
                moduleName: moduleInfo.name,
                version: moduleInfo.version
            )

            SecurityAuditLogger.log(.installationSuccess(
                module: moduleInfo.name,
                version: moduleInfo.version
            ))

            print("  ✅ Installation: SUCCESS")

        } catch {
            SecurityAuditLogger.log(.installationFailed(
                module: moduleInfo.name,
                error: error.localizedDescription
            ))

            try? FileManager.default.removeItem(at: stagingURL)
            try? FileManager.default.removeItem(at: zipURL)

            await downloadCoordinator.completeDownload(
                moduleId: moduleInfo.id,
                attemptId: attemptId,
                reason: .unknown,
                bytesDownloaded: moduleInfo.size,
                expectedBytes: moduleInfo.size
            )

            downloadObserver?.emit(stage: .failed(message: error.localizedDescription))
            throw error
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        downloadObserver?.emit(stage: .integrityCheck)
        print("\n[STAGE 6] POST-INSTALL INTEGRITY CHECK")

        do {
            try await IntegrityValidator.validate(
                moduleURL: finalURL,
                expectedChecksum: moduleInfo.checksum
            )
            print("  ✅ Integrity check: PASSED")

        } catch {
            SecurityAuditLogger.log(.integrityCheckFailed(
                module: moduleInfo.name,
                reason: error.localizedDescription
            ))

            try? FileManager.default.removeItem(at: finalURL)
            
            await downloadCoordinator.completeDownload(
                moduleId: moduleInfo.id,
                attemptId: attemptId,
                reason: .integrityFailed,
                bytesDownloaded: moduleInfo.size,
                expectedBytes: moduleInfo.size
            )

            downloadObserver?.emit(stage: .failed(message: error.localizedDescription))
            throw SecurityError.integrityCheckFailed(reason: error.localizedDescription)
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: stagingURL)

        await downloadCoordinator.completeDownload(
            moduleId: moduleInfo.id,
            attemptId: attemptId,
            reason: .success,
            bytesDownloaded: moduleInfo.size,
            expectedBytes: moduleInfo.size
        )

        downloadObserver?.emit(stage: .completed)

        let stats = await downloadCoordinator.getStatistics()
        print("\n📊 DOWNLOAD STATISTICS")
        print("   Active downloads: \(stats.activeDownloads)")
        print("   Total downloads: \(stats.totalDownloads)")
        print("   Success rate: \(Int(stats.successRate * 100))%")

        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎉 SECURITY PIPELINE COMPLETE!")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        return finalURL
    }

    // MARK: - Download with progress + ETA

    private func downloadFileWithProgress(
        moduleInfo: ModuleInfo,
        attemptId: UUID,
        progressHandler: @escaping (DownloadProgress) -> Void
    ) async throws -> URL {

        guard networkMonitor.current.isConnected else {
            throw NetworkError.noInternet
        }

        guard let url = URL(string: moduleInfo.downloadURL) else {
            throw URLError(.badURL)
        }

        // temp zip path
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("zip")

        await speedEstimator.reset()

        // store active state
        activeProgressHandler = progressHandler
        activeTempURL = tempURL
        activeAttemptId = attemptId
        activeModuleInfo = moduleInfo
        print("⬇️ DOWNLOAD URL:", url.absoluteString)

        return try await withCheckedThrowingContinuation { cont in
            self.activeContinuation = cont

            let task = self.session.downloadTask(with: url)
            self.activeDownloadTask = task

            // Emit initial "0%" quickly for UI
            Task { @MainActor in
                self.activeProgressHandler?(DownloadProgress(
                    fraction: 0,
                    bytesReceived: 0,
                    bytesExpected: moduleInfo.size > 0 ? moduleInfo.size : nil,
                    bytesPerSecond: nil,
                    etaSeconds: nil
                ))
            }

            task.resume()
        }
    }

    // MARK: - Error mapping

    private func mapErrorToDownloadEndReason(_ error: NSError) -> DownloadEndReason {
        // URLError codes
        if error.domain == NSURLErrorDomain {
            switch error.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorDataNotAllowed:
                return .noInternet
                
            case NSURLErrorTimedOut:
                return .timeout
                
            case NSURLErrorCancelled:
                return .cancelled
                
            case NSURLErrorBadServerResponse:
                return .serverError(statusCode: nil)
                
            default:
                break
            }
        }
        
        // Check for HTTP status codes
        if let httpResponse = (error.userInfo[NSURLErrorFailingURLStringErrorKey] as? String).flatMap({ URL(string: $0) }) {
            // This is a simplified check; in reality, you'd extract from response
            return .serverError(statusCode: nil)
        }
        
        return .unknown
    }
}

// MARK: - URLSession delegate (pinning + progress)

extension APIService: URLSessionDelegate, URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        certificatePinner.validate(challenge: challenge, completionHandler: completionHandler)
    }

    // progress stream
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        // Callback thread’ini bloklamayalım.
        Task { [weak self] in
            guard let self else { return }
            guard let attemptId = self.activeAttemptId,
                  let moduleInfo = self.activeModuleInfo else { return }

            let expected: Int64? = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil

            let fraction: Double = {
                if let expected {
                    return min(1.0, max(0.0, Double(totalBytesWritten) / Double(expected)))
                }
                return 0
            }()
            
            let bps = await self.speedEstimator.update(totalBytes: totalBytesWritten)
            let eta = DownloadETAEstimator.etaSeconds(
                bytesReceived: totalBytesWritten,
                bytesExpected: expected,
                bps: bps
            )
            
            if let bps, let eta {
                let speedMB = bps / 1_048_576 // bytes → MB
                print(String(format: "DownloadSpeed: %.2f MB/s", speedMB))
                print(String(format: "EstimatedRemainingTime: %.2f s", eta))
            }
            
            // UI tarafı genelde main thread ister:
            await MainActor.run {
                self.activeProgressHandler?(DownloadProgress(
                    fraction: fraction,
                    bytesReceived: totalBytesWritten,
                    bytesExpected: expected,
                    bytesPerSecond: bps,
                    etaSeconds: eta
                ))
            }

            // Analytics (zaten async)
            await self.downloadCoordinator.updateProgress(
                moduleId: moduleInfo.id,
                attemptId: attemptId,
                bytesReceived: totalBytesWritten,
                expectedBytes: expected
            )
        }
    }

    // finished -> move file to our temp path
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {

        guard let tempURL = activeTempURL else {
            activeContinuation?.resume(throwing: URLError(.badServerResponse))
            Task { await cleanupActiveDownloadState() }
            return
        }

        do {
            // Remove if exists (rare)
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.moveItem(at: location, to: tempURL)
            activeContinuation?.resume(returning: tempURL)
        } catch {
            activeContinuation?.resume(throwing: error)
        }

        Task { await cleanupActiveDownloadState() }
    }

    // if any error
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) async {

        guard let error else { return }

        // ensure single resume
        if let cont = activeContinuation {
            activeContinuation = nil
            cont.resume(throwing: error)
        }
        Task { await cleanupActiveDownloadState() }
    }

    private func cleanupActiveDownloadState() async {
        activeDownloadTask = nil
        activeContinuation = nil
        activeTempURL = nil
        activeProgressHandler = nil
        activeAttemptId = nil
        activeModuleInfo = nil
    }
}
