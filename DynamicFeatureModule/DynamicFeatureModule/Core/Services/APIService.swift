//
//  APIService.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

/// API Service Errors
enum APIError: LocalizedError {
    case invalidURL
    case networkUnavailable
    case unauthorized
    case downloadFailed(reason: String)
    case corruptedData
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkUnavailable:
            return "Network unavailable"
        case .unauthorized:
            return "Unauthorized access"
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .corruptedData:
            return "Corrupted data"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

/// API Service for backend communication
class APIService {
    
    static let shared = APIService()
    
    // MARK: - Properties
    
    private let session: URLSession
    private let baseURL: URL
    private let apiKey: String
    
    // MARK: - Initialization
    
    private init() {
        self.baseURL = ConfigurationManager.API.baseURL
        self.apiKey = ConfigurationManager.API.apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        
        switch ConfigurationManager.App.environment {
        case .development:
            config.timeoutIntervalForRequest = 60
        case .test:
            config.timeoutIntervalForRequest = 30
        case .production:
            config.timeoutIntervalForRequest = 20
        }
        
        // Headers
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-API-Key": apiKey,
            "X-App-Version": BuildConfiguration.fullVersionString,
            "X-Environment": ConfigurationManager.App.environment.rawValue
        ]
        
        self.session = URLSession(configuration: config)
        
        Logger.info("APIService initialized with base URL: \(baseURL.absoluteString)")
    }
    
    // MARK: - Request Methods
    
    func get<T: Decodable>(
        endpoint: String,
        parameters: [String: String]? = nil
    ) async throws -> T {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)
        
        if let parameters = parameters {
            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        Logger.debug("GET request to: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkUnavailable
        }
        
        Logger.debug("Response status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.downloadFailed(reason: "HTTP \(httpResponse.statusCode)")
        }
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            Logger.error("JSON decode error: \(error)")
            throw APIError.corruptedData
        }
    }
    
    /// Generic POST request
    func post<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        Logger.debug("POST request to: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkUnavailable
        }
        
        Logger.debug("Response status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.downloadFailed(reason: "HTTP \(httpResponse.statusCode)")
        }
        
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return decoded
    }
    
    /// Download file
    func downloadFile(from urlString: String, progressHandler: DownloadProgressHandler? = nil) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        Logger.info("Downloading file from: \(url.absoluteString)")
        
        let (localURL, response) = try await session.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkUnavailable
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.downloadFailed(reason: "HTTP \(httpResponse.statusCode)")
        }
        
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: localURL, to: destinationURL)
        
        Logger.info("File downloaded to: \(destinationURL.path)")
        
        return destinationURL
    }
}

// MARK: - Response Models

struct ModuleListResponse: Codable {
    let modules: [ModuleInfo]
}

struct ModuleInfo: Codable {
    let id: String
    let name: String
    let version: String
    let downloadURL: String
    let size: Int64
    let checksum: String?
}

// MARK: - Example Usage

extension APIService {
    
    func fetchAvailableModules() async throws -> [ModuleInfo] {
        let response: ModuleListResponse = try await get(endpoint: "/modules")
        Logger.info("Fetched \(response.modules.count) modules")
        return response.modules
    }
    
    func downloadModule(moduleInfo: ModuleInfo, progressHandler: DownloadProgressHandler? = nil) async throws -> URL {
        let moduleRepoURL = ConfigurationManager.API.moduleRepositoryURL
        let fullURL = moduleRepoURL.appendingPathComponent(moduleInfo.downloadURL)
        
        return try await downloadFile(from: fullURL.absoluteString, progressHandler: progressHandler)
    }
}
