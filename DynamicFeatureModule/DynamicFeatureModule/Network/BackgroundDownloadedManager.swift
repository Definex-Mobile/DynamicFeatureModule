//
//  BackgroundDownloadedManager.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

final class BackgroundDownloadManager: NSObject {
    
    static let shared = BackgroundDownloadManager()
    
    private var session: URLSession!
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private var progressHandlers: [String: DownloadProgressHandler] = [:]
    private var completionHandlers: [String: DownloadCompletionHandler] = [:]
    
    private let sessionIdentifier = "com.dynamicfeature.backgrounddownload"
    
    override private init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        let config = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.waitsForConnectivity = true
        
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    /// Start downloading a module
    func downloadModule(
        metadata: ModuleMetadata,
        progress: DownloadProgressHandler?,
        completion: @escaping DownloadCompletionHandler
    ) {
        let moduleId = metadata.id
        
        if activeTasks[moduleId] != nil {
            print("⚠️ Module \(moduleId) is already being downloaded")
            return
        }
        
        if let resumeData = ResumeDataStore.shared.getResumeData(forModuleId: moduleId) {
            resumeDownload(moduleId: moduleId, resumeData: resumeData, progress: progress, completion: completion)
            return
        }
        
        let task = session.downloadTask(with: metadata.downloadURL)
        activeTasks[moduleId] = task
        progressHandlers[moduleId] = progress
        completionHandlers[moduleId] = completion
        
        task.taskDescription = moduleId
        task.resume()
        
        print("📥 Started downloading module: \(moduleId)")
    }
    
    func resumeDownload(
        moduleId: String,
        resumeData: Data,
        progress: DownloadProgressHandler?,
        completion: @escaping DownloadCompletionHandler
    ) {
        let task = session.downloadTask(withResumeData: resumeData)
        activeTasks[moduleId] = task
        progressHandlers[moduleId] = progress
        completionHandlers[moduleId] = completion
        
        task.taskDescription = moduleId
        task.resume()
        
        print("▶️ Resumed downloading module: \(moduleId)")
    }
    
    func cancelDownload(moduleId: String) {
        guard let task = activeTasks[moduleId] else { return }
        
        task.cancel { resumeDataOrNil in
            if let resumeData = resumeDataOrNil {
                ResumeDataStore.shared.saveResumeData(resumeData, forModuleId: moduleId)
            }
        }
        
        cleanupHandlers(for: moduleId)
        print("⏸️ Cancelled download for module: \(moduleId)")
    }
    
    private func cleanupHandlers(for moduleId: String) {
        activeTasks.removeValue(forKey: moduleId)
        progressHandlers.removeValue(forKey: moduleId)
        completionHandlers.removeValue(forKey: moduleId)
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloadManager: URLSessionDownloadDelegate {
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let moduleId = downloadTask.taskDescription else { return }
        
        let destinationURL = ModuleFileManager.shared.downloadPath(for: moduleId)
        
        do {
            try ModuleFileManager.shared.moveFile(from: location, to: destinationURL)
            
            ResumeDataStore.shared.removeResumeData(forModuleId: moduleId)
            
            DispatchQueue.main.async {
                self.completionHandlers[moduleId]?(.success(destinationURL))
                self.cleanupHandlers(for: moduleId)
            }
            
            print("✅ Download completed for module: \(moduleId)")
            
        } catch {
            DispatchQueue.main.async {
                self.completionHandlers[moduleId]?(.failure(.downloadFailed(error)))
                self.cleanupHandlers(for: moduleId)
            }
        }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let moduleId = downloadTask.taskDescription else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async {
            self.progressHandlers[moduleId]?(progress)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let moduleId = task.taskDescription else { return }
        
        if let error = error as NSError? {
            if error.code == NSURLErrorCancelled,
               let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                ResumeDataStore.shared.saveResumeData(resumeData, forModuleId: moduleId)
                print("💾 Saved resume data for module: \(moduleId)")
            } else {
                DispatchQueue.main.async {
                    self.completionHandlers[moduleId]?(.failure(.downloadFailed(error)))
                    self.cleanupHandlers(for: moduleId)
                }
            }
        }
    }
}

// MARK: - URLSessionDelegate
extension BackgroundDownloadManager: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .backgroundDownloadsFinished, object: nil)
        }
    }
}
