
# 🚀 DynamicFeatureModule

> Enterprise-grade iOS framework for secure, dynamic module loading with multi-environment support

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0+-blue.svg)](https://developer.apple.com/ios/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A robust iOS framework that enables secure, over-the-air dynamic module loading with enterprise-level security features including certificate pinning, checksum validation, and atomic installation.

---

## 📑 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Security Pipeline](#-security-pipeline)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [API Reference](#-api-reference)
- [Security](#-security)

---

## ✨ Features

### 🔒 **Enterprise Security**
- **Certificate Pinning**: SSL certificate validation for secure communications
- **Checksum Verification**: SHA-256/SHA-512 integrity validation
- **Signed Manifests**: Cryptographic signature verification
- **Environment Matching**: Ensures modules match deployment environment
- **Quarantine System**: Isolates suspicious modules automatically

### 🏗️ **Robust Architecture**
- **6-Stage Security Pipeline**: Comprehensive download and installation process
- **Atomic Installation**: Rollback capability on failure
- **Concurrent Download Management**: Configurable parallel downloads
- **Disk Space Validation**: Pre-flight storage checks
- **Safe Extraction**: Path traversal protection during unzipping

### 🌍 **Multi-Environment Support**
- **Development**: localhost testing with verbose logging
- **Test**: Staging environment with analytics
- **Production**: Optimized for performance and security

### 📊 **Monitoring & Logging**
- **Security Audit Logs**: Comprehensive security event tracking
- **Download Statistics**: Success rates and performance metrics
- **Detailed Progress Tracking**: Real-time download progress callbacks

---

## 🏛️ Architecture

```
DynamicFeatureModule/
│── Applications/
├── Core/
│    ├── Configuration/
│    ├── Model/
│    ├── Protocols/
│    ├── Extensions/
│    └── Utilities/                   
│── Installers/
│   └── AtomicInstaller.swift         # Atomic installation with rollback
│── Managers/
│   ├── QuarantineManager.swift       # Suspicious module isolation
│   ├── DiskSpaceManager.swift        # Storage validation
│   └── ConfigurationManager.swift    # Multi-environment config
│── Security/
│   ├── CertificatePinner.swift   # SSL certificate validation
│   ├── ChecksumValidator.swift   # File integrity verification
│   ├── SignatureVerifier.swift   # Manifest signature validation
│   ├── SHA256Validator.swift     # Validate SHA256
│   ├── SafeUnzipper.swift        # Safe unzip file
│   ├── IntegrityValidator.swift  # Post-install validation
│   └── Coordinator/
│       └── DownloadCoordinator.swift # Concurrent download management
│── Services/
│    └── APIService.swift             # Main API & download orchestration
```

### Component Responsibilities

| Component | Responsibility |
|-----------|---------------|
| **APIService** | Orchestrates entire download & security pipeline |
| **CertificatePinner** | Validates SSL certificates against pinned public keys |
| **ChecksumValidator** | Verifies file integrity using cryptographic hashes |
| **SignatureVerifier** | Validates manifest digital signatures |
| **AtomicInstaller** | Ensures installation atomicity with rollback support |
| **DownloadCoordinator** | Manages concurrent downloads and statistics |
| **QuarantineManager** | Isolates and logs suspicious modules |

---

## 🔐 Security Pipeline

The framework implements a comprehensive **6-stage security pipeline**:

```
┌─────────────────────────────────────────────────────────────┐
│                   STAGE 1: PRE-FLIGHT CHECKS                │
├─────────────────────────────────────────────────────────────┤
│  ✓ Download coordinator availability                        │
│  ✓ Disk space validation                                    │
│  ✓ Environment matching                                     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                   STAGE 2: SECURE DOWNLOAD                  │
├─────────────────────────────────────────────────────────────┤
│  ✓ TLS connection with certificate pinning                  │
│  ✓ Real-time progress tracking                              │
│  ✓ Timeout enforcement                                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                STAGE 3: CHECKSUM VERIFICATION               │
├─────────────────────────────────────────────────────────────┤
│  ✓ SHA-256/SHA-512 hash computation                         │
│  ✓ Comparison with expected checksum                        │
│  ✓ Quarantine on mismatch                                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                  STAGE 4: SAFE EXTRACTION                   │
├─────────────────────────────────────────────────────────────┤
│  ✓ Path traversal protection                                │
│  ✓ Staging directory isolation                              │
│  ✓ Size limit enforcement                                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                STAGE 5: ATOMIC INSTALLATION                 │
├─────────────────────────────────────────────────────────────┤
│  ✓ Transactional copy operation                             │
│  ✓ Automatic rollback on failure                            │
│  ✓ Version management                                       │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│            STAGE 6: POST-INSTALL INTEGRITY CHECK            │
├─────────────────────────────────────────────────────────────┤
│  ✓ Final integrity validation                               │
│  ✓ Security audit logging                                   │
│  ✓ Statistics update                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### 1. Initialize Configuration

The framework automatically detects your environment based on build configuration:

```swift
import DynamicFeatureModule

// Configuration is initialized automatically
let config = ConfigurationManager.shared

print("Environment: \(config.environment.displayName)")
print("Backend URL: \(config.backendURL)")
```

### 2. Fetch Available Modules

```swift
Task {
    do {
        let modules = try await apiService.fetchAvailableModules()
        
        for module in modules {
            print("📦 \(module.name) v\(module.version)")
            print("   Size: \(module.size / 1024 / 1024) MB")
            print("   Checksum: \(module.checksum)")
        }
    } catch {
        print("Error fetching modules: \(error)")
    }
}
```

### 3. Download and Install Module

```swift
Task {
    do {
        let moduleURL = try await apiService.downloadModule(
            moduleInfo: selectedModule,
            progressHandler: { progress in
                print("Download progress: \(Int(progress * 100))%")
            }
        )
        
        print("✅ Module installed at: \(moduleURL.path)")
        
    } catch {
        print("❌ Installation failed: \(error)")
    }
}
```

---

## ⚙️ Configuration

### Environment Configuration

The framework supports three environments with distinct configurations:

#### Development

```swift
struct DevelopmentConfig: AppEnvironmentConfigurable {
    let baseURL = URL(string: "http://localhost:8000")!
    let debugMode = true
    let loggingEnabled = true
    let maxConcurrentDownloads = 3
}
```

#### Test

```swift
struct TestConfig: AppEnvironmentConfigurable {
    let baseURL = URL(string: "https://test-api.dynamicmodule.com")!
    let debugMode = true
    let analyticsEnabled = true
    let maxConcurrentDownloads = 3
}
```

#### Production

```swift
struct ProductionConfig: AppEnvironmentConfigurable {
    let baseURL = URL(string: "https://api.dynamicmodule.com")!
    let debugMode = false
    let loggingEnabled = false
    let maxConcurrentDownloads = 5
}
```

### Security Configuration

Configure security parameters in `SecurityConfiguration.swift`:

```swift
struct SecurityConfiguration {
    static let checksumAlgorithm: ChecksumAlgorithm = .sha256
    static let downloadTimeout: TimeInterval = 300.0
    static let enforceEnvironmentMatch = true
    static let enableCertificatePinning = true
    static let maxFileSizeBytes: Int64 = 500_000_000 // 500 MB
}
```

### Accessing Configuration

```swift
// Direct access
let baseURL = ConfigurationManager.API.baseURL
let apiKey = ConfigurationManager.API.apiKey

// App settings
let isDebug = ConfigurationManager.App.isDebug
let maxDownloads = ConfigurationManager.App.maxConcurrentDownloads
```

---

## 📚 API Reference

### APIService

#### `fetchAvailableModules() async throws -> [ModuleInfo]`

Fetches the list of available modules from the backend.

**Returns:** Array of `ModuleInfo` objects

**Throws:** 
- `URLError` - Network errors
- `DecodingError` - JSON parsing errors
- `SecurityError.environmentMismatch` - Environment validation failure

**Example:**

```swift
let modules = try await apiService.fetchAvailableModules()
```

---

#### `downloadModule(moduleInfo:progressHandler:) async throws -> URL`

Downloads and installs a module through the complete security pipeline.

**Parameters:**
- `moduleInfo: ModuleInfo` - Module metadata
- `progressHandler: (Double) -> Void` - Progress callback (0.0 to 1.0)

**Returns:** `URL` - Local path to installed module

**Throws:**
- `SecurityError.checksumMismatch` - Integrity check failed
- `SecurityError.integrityCheckFailed` - Post-install validation failed
- `URLError` - Download errors

**Example:**

```swift
let url = try await apiService.downloadModule(
    moduleInfo: module,
    progressHandler: { progress in
        updateUI(progress: progress)
    }
)
```

---

### ModuleInfo

```swift
struct ModuleInfo {
    let id: String
    let name: String
    let version: String
    let checksum: String
    let size: Int64
    let environment: String
    let downloadURL: String
}
```

---

### DownloadCoordinator

#### `canStartDownload(moduleId:) async throws`

Validates if a download can start based on concurrent limits.

#### `getStatistics() async -> DownloadStatistics`

Returns download statistics including success rate.

```swift
let stats = await coordinator.getStatistics()
print("Success rate: \(Int(stats.successRate * 100))%")
```

---

## 🔒 Security

### Certificate Pinning

The framework validates SSL certificates against pinned public keys:

```swift
class CertificatePinner {
    func validate(
        challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )
}
```

**Configuration:**
Add your server's public key hash to the certificate pinning configuration.

---

### Checksum Validation

All downloaded files are validated using cryptographic hashes:

```swift
try ChecksumValidator.validate(
    fileURL: downloadedFile,
    expectedChecksum: module.checksum
)
```

**Supported Algorithms:**
- SHA-256 (recommended)
- SHA-512 (high security)

---

### Signed Manifests

Module manifests are cryptographically signed:

```swift
try SignatureVerifier.verifySignedManifest(manifest)
```

---

### Quarantine System

Suspicious modules are automatically quarantined:

```swift
try await quarantineManager.quarantine(
    moduleId: module.id,
    path: filePath,
    reason: "Checksum mismatch"
)
```

Quarantined files are:
- Moved to isolated directory
- Logged in security audit trail
- Prevented from loading

---

## 🏗️ Project Structure Best Practices

### Modular Architecture

The project follows a clean, modular architecture:

- **Core**: Framework core components
- **Services**: Business logic and API communication
- **Security**: Security-related functionality
- **Installers**: Module installation logic
- **Managers**: Resource and state management
- **Models**: Data models and DTOs

### Dependency Injection

The framework uses singletons with dependency injection support for testability.

---

## 📊 Performance

### Optimization Features

- **Concurrent Downloads**: Up to 5 parallel downloads in production
- **Download Resumption**: Supports resume after interruption
- **Cache Management**: Configurable cache expiration
- **Memory Efficiency**: Streams large files instead of loading into memory

### Benchmarks

| Operation | Time | Memory |
|-----------|------|--------|
| Fetch Modules (10 items) | ~200ms | 5MB |
| Download Module (50MB) | ~8s (on WiFi) | 15MB |
| Checksum Validation | ~500ms | 10MB |
| Installation | ~1s | 20MB |

---

# Dynamic Feature Module – Backend

Backend service for the Dynamic Feature Module system.  
Provides API endpoints for module distribution, validation, and configuration.

---

## 🚀 Backend Setup

### 📁 Project Directory
```bash
cd DynamicFeatureModule/back-end
```

📦 Install Dependencies

```bash
npm install
```

▶️ Start Server

```bash
npm start
```

