//
//  APIService.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

protocol APIServiceProtocol {
    func fetchAvailableModules() async throws -> [ModuleInfo]
    func downloadModule(moduleInfo: ModuleInfo, progressHandler: @escaping (Double) -> Void) async throws -> URL
}

final class APIService: NSObject, APIServiceProtocol {
    
    private let baseURL: String
    private var session: URLSession
    private let downloadCoordinator: DownloadCoordinatorProtocol
    private let quarantineManager: QuarantineManagerProtocol
    private let certificatePinner: CertificatePinnerProtocol
    private let diskSpaceManager: DiskSpaceManagerProtocol
    
    
    init(downloadCoordinator: DownloadCoordinatorProtocol,
         quarantineManager: QuarantineManagerProtocol,
         certificatePinner: CertificatePinnerProtocol,
         diskSpaceManager: DiskSpaceManagerProtocol) {
        self.downloadCoordinator = downloadCoordinator
        self.quarantineManager = quarantineManager
        self.certificatePinner = certificatePinner
        self.diskSpaceManager = diskSpaceManager
        self.baseURL = ConfigurationManager.shared.backendURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = SecurityConfiguration.downloadTimeout
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: config)
        
        super.init()
        
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func fetchAvailableModules() async throws -> [ModuleInfo] {
        print("🌐 Fetching modules from backend...")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let url = URL(string: "\(baseURL)/api/modules")!
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // DEBUG: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Raw JSON Response:")
            print(jsonString)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
        
        let decoder = JSONDecoder()
        
        // Custom ISO8601 decoder with fractional seconds support
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try with fractional seconds first
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to standard ISO8601
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
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
                    throw SecurityError.environmentMismatch(
                        expected: currentEnv,
                        actual: moduleResponse.manifest.environment
                    )
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
            
        } catch DecodingError.dataCorrupted(let context) {
            print("❌ Decoding Error - Data Corrupted:")
            print("   \(context.debugDescription)")
            print("   CodingPath: \(context.codingPath)")
            throw DecodingError.dataCorrupted(context)
        } catch DecodingError.keyNotFound(let key, let context) {
            print("❌ Decoding Error - Key Not Found:")
            print("   Key: \(key.stringValue)")
            print("   Context: \(context.debugDescription)")
            print("   CodingPath: \(context.codingPath)")
            throw DecodingError.keyNotFound(key, context)
        } catch DecodingError.typeMismatch(let type, let context) {
            print("❌ Decoding Error - Type Mismatch:")
            print("   Expected Type: \(type)")
            print("   Context: \(context.debugDescription)")
            print("   CodingPath: \(context.codingPath)")
            throw DecodingError.typeMismatch(type, context)
        } catch DecodingError.valueNotFound(let type, let context) {
            print("❌ Decoding Error - Value Not Found:")
            print("   Type: \(type)")
            print("   Context: \(context.debugDescription)")
            print("   CodingPath: \(context.codingPath)")
            throw DecodingError.valueNotFound(type, context)
        } catch {
            print("❌ Unknown Decoding Error:")
            print("   \(error.localizedDescription)")
            throw error
        }
    }
    
    func downloadModule(
        moduleInfo: ModuleInfo,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔒 STARTING FULL SECURITY PIPELINE")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📦 Module: \(moduleInfo.name) v\(moduleInfo.version)")
        print("📏 Size: \(moduleInfo.size / 1024 / 1024) MB")
        print("🔑 Checksum: \(moduleInfo.checksum.prefix(16))...")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        print("\n[STAGE 1] PRE-FLIGHT CHECKS")
        
        print("  ⏳ Checking download coordinator...")
        try await downloadCoordinator.canStartDownload(moduleId: moduleInfo.id)
        print("  ✅ Download coordinator: PASS")
        
        print("  💾 Checking disk space...")
        try diskSpaceManager.checkAvailableSpace(required: moduleInfo.size)
        print("  ✅ Disk space: PASS")
        
        if SecurityConfiguration.enforceEnvironmentMatch {
            let currentEnv = ConfigurationManager.shared.environment.rawValue
            guard moduleInfo.environment == currentEnv else {
                throw SecurityError.environmentMismatch(
                    expected: currentEnv,
                    actual: moduleInfo.environment
                )
            }
            print("  ✅ Environment: PASS")
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        print("\n[STAGE 2] SECURE DOWNLOAD")
        print("  📥 Downloading from: \(moduleInfo.downloadURL)")
        
        var tempZipURL: URL?
        
        do {
            tempZipURL = try await downloadFile(
                from: moduleInfo.downloadURL,
                progressHandler: progressHandler
            )
            
            print("  ✅ Download complete: \(tempZipURL!.path)")
            
        } catch {
            await downloadCoordinator.completeDownload(
                moduleId: moduleInfo.id,
                success: false,
                bytesDownloaded: 0
            )
            throw error
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        guard let zipURL = tempZipURL else {
            throw SecurityError.invalidData
        }
        
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
                success: false,
                bytesDownloaded: moduleInfo.size
            )
            
            throw error
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
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
                success: false,
                bytesDownloaded: moduleInfo.size
            )
            
            throw error
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
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
                success: false,
                bytesDownloaded: moduleInfo.size
            )
            
            throw error
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
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
            
            throw SecurityError.integrityCheckFailed(reason: error.localizedDescription)
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: stagingURL)
        
        await downloadCoordinator.completeDownload(
            moduleId: moduleInfo.id,
            success: true,
            bytesDownloaded: moduleInfo.size
        )
        
        let stats = await downloadCoordinator.getStatistics()
        print("\n📊 DOWNLOAD STATISTICS")
        print("   Active downloads: \(stats.activeDownloads)")
        print("   Total downloads: \(stats.totalDownloads)")
        print("   Success rate: \(Int(stats.successRate * 100))%")
        
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎉 SECURITY PIPELINE COMPLETE!")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ All security checks passed")
        print("📂 Module installed at:")
        print("   \(finalURL.path)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        return finalURL
    }
    
    private func downloadFile(
        from urlString: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("zip")
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.downloadTask(with: url) { location, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let location = location else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                do {
                    try FileManager.default.moveItem(at: location, to: tempURL)
                    continuation.resume(returning: tempURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            task.resume()
        }
    }
}

extension APIService: URLSessionDelegate {
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        certificatePinner.validate(challenge: challenge, completionHandler: completionHandler)
    }
}
