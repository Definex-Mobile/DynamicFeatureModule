//
//  ModuleAPIClient.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

final class ModuleAPIClient {
    
    static let shared = ModuleAPIClient()
    
    private let session: URLSession
    private let baseURL: String
    
    // MARK: - Demo Configuration
    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    func fetchAvailableModules(completion: @escaping (Result<[ModuleMetadata], ModuleError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/modules") else {
            completion(.failure(.invalidMetadata))
            return
        }
        
        print("📡 Fetching modules from: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(.failure(.invalidMetadata))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 Raw JSON response:")
                print(jsonString)
            }
            
            do {
                let decoder = JSONDecoder()
                let modulesResponse = try decoder.decode(ModulesResponse.self, from: data)
                
                print("✅ Successfully parsed \(modulesResponse.modules.count) modules")
                modulesResponse.modules.forEach { module in
                    print("  • \(module.name) v\(module.version.stringValue)")
                }
                
                completion(.success(modulesResponse.modules))
            } catch let decodingError as DecodingError {
                print("❌ JSON Decoding Error:")
                
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("  Missing key: '\(key.stringValue)'")
                    print("  Context: \(context.debugDescription)")
                    print("  Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                    
                case .typeMismatch(let type, let context):
                    print("  Type mismatch: Expected \(type)")
                    print("  Context: \(context.debugDescription)")
                    print("  Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                    
                case .valueNotFound(let type, let context):
                    print("  Value not found: \(type)")
                    print("  Context: \(context.debugDescription)")
                    
                case .dataCorrupted(let context):
                    print("  Data corrupted")
                    print("  Context: \(context.debugDescription)")
                    
                @unknown default:
                    print("  Unknown decoding error")
                }
                
                completion(.failure(.invalidMetadata))
            } catch {
                print("❌ Unexpected error: \(error)")
                completion(.failure(.invalidMetadata))
            }
        }
        
        task.resume()
    }
    
    func fetchModule(id: String, completion: @escaping (Result<ModuleMetadata, ModuleError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/modules/\(id)") else {
            completion(.failure(.moduleNotFound(id)))
            return
        }
        
        print("📡 Fetching module: \(id)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(.failure(.moduleNotFound(id)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let metadata = try decoder.decode(ModuleMetadata.self, from: data)
                print("✅ Successfully parsed module: \(metadata.name)")
                completion(.success(metadata))
            } catch {
                print("❌ Decoding error: \(error)")
                completion(.failure(.invalidMetadata))
            }
        }
        
        task.resume()
    }
}
