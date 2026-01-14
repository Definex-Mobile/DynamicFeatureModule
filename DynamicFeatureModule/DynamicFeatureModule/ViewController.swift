//
//  ViewController.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 6.01.2026.
//

import UIKit

class ViewController: UIViewController {
    
    private let environmentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
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
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        return progress
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
    
    private let moduleManager = DynamicModuleManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupActions()
        setupEnvironmentLabel()
        
        logMessage("App started")
        logMessage("Environment: \(Environment.current.displayName)")
        logMessage("Backend: http://localhost:8000")
    }
    
    private func setupUI() {
        view.addSubview(environmentLabel)
        view.addSubview(titleLabel)
        view.addSubview(testButton)
        view.addSubview(statusLabel)
        view.addSubview(progressView)
        view.addSubview(downloadButton)
        view.addSubview(detailsTextView)
        
        NSLayoutConstraint.activate([
            environmentLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            environmentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            environmentLabel.heightAnchor.constraint(equalToConstant: 32),
            environmentLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
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
            
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            downloadButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
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
        let env = Environment.current
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
    
    @objc private func testButtonTapped() {
        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("Testing backend...")
        statusLabel.text = "Testing backend connection..."
        testButton.isEnabled = false
        
        guard let url = URL(string: "http://localhost:8000/api/test") else {
            logMessage("❌ Invalid URL")
            statusLabel.text = "Error: Invalid URL"
            testButton.isEnabled = true
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.testButton.isEnabled = true
                
                if let error = error {
                    self?.logMessage("❌ Connection failed:")
                    self?.logMessage("   \(error.localizedDescription)")
                    self?.statusLabel.text = "❌ Backend not running!\nStart: ./start-demo.sh"
                    return
                }
                
                guard let data = data else {
                    self?.logMessage("❌ No data received")
                    self?.statusLabel.text = "Error: No data"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self?.logMessage("✅ Backend is working!")
                        self?.logMessage("Response:")
                        self?.logMessage(self?.formatJSON(json) ?? "")
                        
                        if let availableModules = json["availableModules"] as? Int {
                            self?.statusLabel.text = "✅ Backend OK\n\(availableModules) modules ready"
                        } else {
                            self?.statusLabel.text = "✅ Backend connected"
                        }
                    }
                } catch {
                    self?.logMessage("❌ Parse error: \(error)")
                    self?.statusLabel.text = "Error: Invalid response"
                }
            }
        }
        
        task.resume()
    }
    
    @objc private func downloadButtonTapped() {
        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("Starting download flow...")
        statusLabel.text = "Fetching available modules..."
        downloadButton.isEnabled = false
        progressView.isHidden = true
        
        // Fetch modules from backend
        moduleManager.fetchAvailableModules { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let modules):
                self.logMessage("✅ Received \(modules.count) modules")
                self.logMessage("Environment: \(Environment.current)")
                
                modules.forEach { module in
                    self.logMessage("  • \(module.name) v\(module.version.stringValue)")
                }
                
                if let lastModule = modules.last {
                    self.downloadModule(lastModule)
                } else {
                    self.logMessage("⚠️  No modules available")
                    self.statusLabel.text = "No modules available"
                    self.downloadButton.isEnabled = true
                }
                
            case .failure(let error):
                self.logMessage("❌ Fetch failed:")
                self.logMessage("   \(error.localizedDescription)")
                
                if error.localizedDescription.contains("Could not connect") {
                    self.statusLabel.text = "❌ Backend not running!\nRun: ./start-demo.sh"
                } else {
                    self.statusLabel.text = "Error: \(error.localizedDescription)"
                }
                
                self.downloadButton.isEnabled = true
            }
        }
    }
    
    private func downloadModule(_ metadata: ModuleMetadata) {
        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("Downloading: \(metadata.name)")
        logMessage("Version: \(metadata.version.stringValue)")
        logMessage("Size: \((metadata.size ?? 0) / 1024) KB")
        logMessage("Checksum: \(metadata.checksum.prefix(20))...")
        
        statusLabel.text = "Downloading \(metadata.name)..."
        progressView.isHidden = false
        progressView.progress = 0.0
        
        moduleManager.downloadModule(
            metadata: metadata,
            progress: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progressView.progress = Float(progress)
                    let percentage = Int(progress * 100)
                    self?.statusLabel.text = "Downloading \(metadata.name)...\n\(percentage)%"
                    
                    if percentage % 25 == 0 {
                        self?.logMessage("⏳ Progress: \(percentage)%")
                    }
                }
            },
            completion: { [weak self] result in
                guard let self = self else { return }
                
                self.progressView.isHidden = true
                self.downloadButton.isEnabled = true
                
                switch result {
                case .success(let contentURL):
                    self.logMessage("✅ Download complete!")
                    self.logMessage("📂 Location:")
                    self.logMessage("   \(contentURL.path)")
                    self.statusLabel.text = "✅ Module downloaded!\n\(metadata.name) v\(metadata.version.stringValue)"
                    
                    // List contents
                    self.listModuleContents(contentURL)
                    
                case .failure(let error):
                    self.logMessage("❌ Download failed:")
                    self.logMessage("   \(error.localizedDescription)")
                    self.statusLabel.text = "❌ Download failed\n\(error.localizedDescription)"
                }
            }
        )
    }
    
    private func listModuleContents(_ contentURL: URL) {
        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("📋 Module contents:")
        
        let fileManager = FileManager.default
        if let contents = try? fileManager.contentsOfDirectory(
            at: contentURL,
            includingPropertiesForKeys: [.fileSizeKey]
        ) {
            contents.forEach { url in
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    self.logMessage("  • \(url.lastPathComponent) (\(size) bytes)")
                } else {
                    self.logMessage("  • \(url.lastPathComponent)")
                }
            }
        }
        
        logMessage("━━━━━━━━━━━━━━━━━━━━")
        logMessage("✅ Demo complete!")
    }
    
    // MARK: - Helpers
    
    private func logMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logLine = "[\(timestamp)] \(message)\n"
        
        print(logLine, terminator: "")
        
        DispatchQueue.main.async {
            self.detailsTextView.text += logLine
            
            let bottom = NSRange(location: self.detailsTextView.text.count - 1, length: 1)
            self.detailsTextView.scrollRangeToVisible(bottom)
        }
    }
    
    private func formatJSON(_ json: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }
}
