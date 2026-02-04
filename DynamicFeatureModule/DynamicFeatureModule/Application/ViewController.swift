//
//  ViewController.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 6.01.2026.
//

import UIKit

final class ViewController: UIViewController {

    // MARK: - UI Components

    private let environmentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let networkStatusBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Dynamic Module Demo"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let testButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test Backend", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready to test\nTap 'Test Backend' first"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stageLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        return progress
    }()

    private let downloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Download Module", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let detailsTextView: UITextView = {
        let textView = UITextView()
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    // MARK: - State

    private var apiService: APIServiceProtocol!
    private var networkMonitor: NetworkMonitoring!
    private var downloadObserver: DownloadObserver!
    private var lastLoggedPercentBucket: Int = -1
    private var currentModuleName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        inject()
        setupUI()
        setupActions()
        setupEnvironmentLabel()
        setupNetworkMonitoring()
        setupDownloadObserver()

        logMessage("App started")
        logMessage("Environment: \(ConfigurationManager.shared.environment.displayName)")
        logMessage("Backend: http://localhost:8000")
    }

    // MARK: - Layout

    private func setupUI() {
        view.addSubview(environmentLabel)
        view.addSubview(networkStatusBadge)
        view.addSubview(titleLabel)
        view.addSubview(testButton)
        view.addSubview(statusLabel)
        view.addSubview(stageLabel)
        view.addSubview(spinner)
        view.addSubview(progressView)
        view.addSubview(downloadButton)
        view.addSubview(detailsTextView)

        NSLayoutConstraint.activate([
            environmentLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            environmentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            environmentLabel.heightAnchor.constraint(equalToConstant: 32),
            environmentLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            networkStatusBadge.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            networkStatusBadge.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            networkStatusBadge.heightAnchor.constraint(equalToConstant: 32),
            networkStatusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),

            titleLabel.topAnchor.constraint(equalTo: environmentLabel.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            testButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 200),
            testButton.heightAnchor.constraint(equalToConstant: 50),

            statusLabel.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 30),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            stageLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            stageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            spinner.topAnchor.constraint(equalTo: stageLabel.bottomAnchor, constant: 6),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            progressView.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            downloadButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 6),
            downloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 200),
            downloadButton.heightAnchor.constraint(equalToConstant: 50),

            detailsTextView.topAnchor.constraint(equalTo: downloadButton.bottomAnchor, constant: 20),
            detailsTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            detailsTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            detailsTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func setupActions() {
        testButton.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
    }

    private func setupEnvironmentLabel() {
        let env = ConfigurationManager.shared.environment
        let emoji: String
        let backgroundColor: UIColor
        let textColor: UIColor

        switch env {
        case .development:
            emoji = "🔧"
            backgroundColor = .systemOrange.withAlphaComponent(0.2)
            textColor = .systemOrange
        case .test:
            emoji = "🧪"
            backgroundColor = .systemBlue.withAlphaComponent(0.2)
            textColor = .systemBlue
        case .production:
            emoji = "🚀"
            backgroundColor = .systemGreen.withAlphaComponent(0.2)
            textColor = .systemGreen
        }

        environmentLabel.text = "  \(emoji) \(env.displayName)  "
        environmentLabel.backgroundColor = backgroundColor
        environmentLabel.textColor = textColor
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.observe { [weak self] status in
            DispatchQueue.main.async {
                self?.updateNetworkBadge(status)
            }
        }
    }
    
    private func updateNetworkBadge(_ status: NetworkStatus) {
        let type = networkMonitor.connectionType
        let emoji: String
        let bgColor: UIColor
        let textColor: UIColor
        
        switch type {
        case .wifi:
            emoji = "📶"
            bgColor = .systemGreen.withAlphaComponent(0.2)
            textColor = .systemGreen
        case .cellular:
            emoji = "📱"
            bgColor = .systemOrange.withAlphaComponent(0.2)
            textColor = .systemOrange
        case .wired:
            emoji = "🔌"
            bgColor = .systemBlue.withAlphaComponent(0.2)
            textColor = .systemBlue
        case .none:
            emoji = "❌"
            bgColor = .systemRed.withAlphaComponent(0.2)
            textColor = .systemRed
        case .loopback, .other:
            emoji = "🌐"
            bgColor = .systemGray.withAlphaComponent(0.2)
            textColor = .systemGray
        }
        
        var statusText = "\(emoji) \(type.rawValue)"
        
        if networkMonitor.isConstrainedConnection {
            statusText += " • Low Data"
            textColor.withAlphaComponent(0.8)
        }
        
        networkStatusBadge.text = "  \(statusText)  "
        networkStatusBadge.backgroundColor = bgColor
        networkStatusBadge.textColor = textColor
    }
    
    // MARK: - Download Observer
    
    private func setupDownloadObserver() {
        downloadObserver.subscribe { [weak self] stage in
            DispatchQueue.main.async {
                self?.updateStageUI(stage)
            }
        }
    }
    
    private func updateStageUI(_ stage: DownloadStage) {
        switch stage {
        case .checkingNetwork:
            stageLabel.text = "🌐 Checking network..."
            stageLabel.textColor = .systemBlue
            
        case .preflightChecks:
            stageLabel.text = "✅ Running pre-flight checks..."
            stageLabel.textColor = .systemBlue
            
        case .downloading:
            stageLabel.text = "📥 Downloading..."
            stageLabel.textColor = .systemBlue
            
        case .verifyingChecksum:
            stageLabel.text = "🔍 Verifying checksum..."
            stageLabel.textColor = .systemPurple
            
        case .extracting:
            stageLabel.text = "📦 Extracting files..."
            stageLabel.textColor = .systemPurple
            
        case .installing:
            stageLabel.text = "⚙️ Installing module..."
            stageLabel.textColor = .systemIndigo
            
        case .integrityCheck:
            stageLabel.text = "🔐 Running integrity check..."
            stageLabel.textColor = .systemIndigo
            
        case .completed:
            stageLabel.text = "✅ Download complete!"
            stageLabel.textColor = .systemGreen
            
        case .failed(let message):
            stageLabel.text = "❌ Failed: \(message)"
            stageLabel.textColor = .systemRed
        }
    }

    // MARK: - Actions

    @objc private func testButtonTapped() {
        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("Testing backend...")

        setUI(isBusy: true, showsProgress: false)
        testButton.isEnabled = false
        downloadButton.isEnabled = false
        stageLabel.text = ""

        guard let url = URL(string: "http://localhost:8000/api/test") else {
            failUI(message: "Invalid URL")
            testButton.isEnabled = true
            downloadButton.isEnabled = true
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.testButton.isEnabled = true
                self.downloadButton.isEnabled = true
                self.spinner.stopAnimating()

                if let error = error {
                    self.logMessage("❌ Connection failed:")
                    self.logMessage("   \(error.localizedDescription)")
                    self.statusLabel.text = "❌ Backend not running!\nStart: npm start"
                    return
                }

                guard let data = data else {
                    self.failUI(message: "No data")
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.logMessage("✅ Backend is working!")
                        self.logMessage("Response:")
                        self.logMessage(self.formatJSON(json))

                        if let availableModules = json["availableModules"] as? Int {
                            self.statusLabel.text = "✅ Backend OK\n\(availableModules) modules ready"
                        } else {
                            self.statusLabel.text = "✅ Backend connected"
                        }
                    }
                } catch {
                    self.failUI(message: "Invalid response")
                }
            }
        }
        task.resume()
    }

    @objc private func downloadButtonTapped() {
        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("Starting download flow...")

        setUI(isBusy: true, showsProgress: false)
        downloadButton.isEnabled = false
        testButton.isEnabled = false
        lastLoggedPercentBucket = -1
        stageLabel.text = "🌐 Fetching modules..."
        
        Task {
            do {
                let modules = try await apiService.fetchAvailableModules()

                await MainActor.run {
                    self.logMessage("✅ Received \(modules.count) modules")
                    modules.forEach { module in
                        self.logMessage("  • \(module.name) v\(module.version)")
                    }

                    guard let lastModule = modules.first else {
                        self.logMessage("⚠️  No modules available")
                        self.statusLabel.text = "No modules available"
                        self.stageLabel.text = ""
                        self.setUI(isBusy: false, showsProgress: false)
                        self.downloadButton.isEnabled = true
                        self.testButton.isEnabled = true
                        return
                    }

                    self.checkAndDownloadModule(lastModule)
                }

            } catch {
                await MainActor.run {
                    self.failUI(message: error.localizedDescription)
                    self.downloadButton.isEnabled = true
                    self.testButton.isEnabled = true
                }
            }
        }
    }
    
    // MARK: - Download Flow
    
    private func checkAndDownloadModule(_ module: ModuleInfo) {
        // Check if cellular download needs confirmation
        if networkMonitor.connectionType == .cellular {
            let sizeMB = Double(module.size) / 1024 / 1024
            
            if sizeMB > 1.0 && SecurityConfiguration.warnOnCellularDownloads {
                showCellularWarning(module: module, sizeMB: sizeMB) { [weak self] in
                    self?.downloadModule(module)
                }
                return
            }
        }
        
        downloadModule(module)
    }
    
    private func showCellularWarning(module: ModuleInfo, sizeMB: Double, onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "📱 Cellular Download",
            message: String(format: "You're about to download %.1f MB over cellular network. This may use your data plan.\n\nModule: %@\nVersion: %@", sizeMB, module.name, module.version),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.statusLabel.text = "Download cancelled"
            self?.stageLabel.text = ""
            self?.setUI(isBusy: false, showsProgress: false)
            self?.downloadButton.isEnabled = true
            self?.testButton.isEnabled = true
        })
        
        alert.addAction(UIAlertAction(title: "Download Anyway", style: .default) { _ in
            onConfirm()
        })
        
        present(alert, animated: true)
    }

    private func downloadModule(_ module: ModuleInfo) {
        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("Downloading: \(module.name)")
        logMessage("Version: \(module.version)")
        logMessage("Size: \(formatBytes(module.size))")
        logMessage("Environment: \(module.environment)")
        logMessage("Checksum: \(module.checksum.prefix(20))...")

        currentModuleName = module.name
        setUI(isBusy: false, showsProgress: true)
        progressView.progress = 0.0
        lastLoggedPercentBucket = -1

        statusLabel.text = "Downloading \(module.name)…\n0%  •  — B/s  •  ETA —"
        stageLabel.text = "📥 Starting download..."

        Task {
            do {
                let localURL = try await apiService.downloadModule(
                    moduleInfo: module,
                    progressHandler: { progress in
                        Task { @MainActor in
                            self.applyProgress(progress, moduleName: module.name)
                        }
                    }
                )

                await MainActor.run {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.spinner.stopAnimating()
                        self.progressView.isHidden = true
                        self.downloadButton.isEnabled = true
                        self.testButton.isEnabled = true

                        self.logMessage("✅ Download complete!")
                        self.logMessage("📂 Location:")
                        self.logMessage("   \(localURL.path)")
                        self.statusLabel.text = "✅ Module downloaded!\n\(module.name) v\(module.version)"
                        self.stageLabel.text = "✅ Installation complete!"

                        self.listModuleContents(localURL)
                    }
                }

            } catch {
                await MainActor.run {
                    self.progressView.isHidden = true
                    self.spinner.stopAnimating()
                    self.downloadButton.isEnabled = true
                    self.testButton.isEnabled = true

                    self.logMessage("❌ Download failed:")
                    self.logMessage("   \(error.localizedDescription)")
                    self.statusLabel.text = "❌ Download failed"
                    self.stageLabel.text = "❌ \(self.prettyError(error))"
                }
            }
        }
    }

    // MARK: - Progress UI

    private func applyProgress(_ progress: DownloadProgress, moduleName: String) {
        let percent = progress.percentInt
        let speedText = formatSpeed(progress.bytesPerSecond)
        let etaText = formatETA(progress.etaSeconds)

        progressView.progress = Float(progress.fraction)
        
        statusLabel.text = "Downloading \(moduleName)…\n\(percent)%  •  \(speedText)  •  ETA \(etaText)"

        // Log at 0/25/50/75/100e
        let bucket = (percent / 25) * 25
        if bucket != lastLoggedPercentBucket && bucket % 25 == 0 {
            lastLoggedPercentBucket = bucket
            logMessage("⏳ Progress: \(bucket)% | \(speedText) | ETA \(etaText)")
        }

        if progress.fraction >= 1.0 {
            progressView.progress = 1.0
            if lastLoggedPercentBucket != 100 {
                lastLoggedPercentBucket = 100
                logMessage("⏳ Progress: 100% | \(speedText) | ETA 00:00")
            }
        }
    }

    // MARK: - UI Helpers

    private func setUI(isBusy: Bool, showsProgress: Bool) {
        if showsProgress {
            spinner.stopAnimating()
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
            if isBusy { spinner.startAnimating() }
            else { spinner.stopAnimating() }
        }
    }

    private func failUI(message: String) {
        setUI(isBusy: false, showsProgress: false)
        stageLabel.text = "❌ \(message)"
        stageLabel.textColor = .systemRed
        logMessage("❌ \(message)")
    }

    // MARK: - File Listing

    private func listModuleContents(_ contentURL: URL) {
        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("📋 Module contents:")

        let fm = FileManager.default
        if let contents = try? fm.contentsOfDirectory(at: contentURL, includingPropertiesForKeys: [.fileSizeKey]) {
            contents.forEach { url in
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    logMessage("  • \(url.lastPathComponent) (\(formatBytes(Int64(size))))")
                } else {
                    logMessage("  • \(url.lastPathComponent)")
                }
            }
        }

        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("✅ Demo complete!")
    }
    
    private func logMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logLine = "[\(timestamp)] \(message)\n"
        print(logLine, terminator: "")

        DispatchQueue.main.async {
            self.detailsTextView.text += logLine
            let bottom = NSRange(location: max(self.detailsTextView.text.count - 1, 0), length: 1)
            self.detailsTextView.scrollRangeToVisible(bottom)
        }
    }

    // MARK: - Dependency Injection

    func inject() {
        let networkMonitor = NetworkMonitor()
        let downloadCoordinator = DownloadCoordinator()
        let quarantineManager = QuarantineManager()
        let certificatePinner = CertificatePinner()
        let diskSpaceManager = DiskSpaceManager()
        let downloadObserver = DownloadObserver()
        let speedEstimator = DownloadThroughputEstimator()

        let service = APIService(
            downloadCoordinator: downloadCoordinator,
            quarantineManager: quarantineManager,
            certificatePinner: certificatePinner,
            diskSpaceManager: diskSpaceManager,
            networkMonitor: networkMonitor,
            downloadObserver: downloadObserver,
            speedEstimator: speedEstimator
        )
        
        self.apiService = service
        self.networkMonitor = networkMonitor
        self.downloadObserver = downloadObserver
    }
}
