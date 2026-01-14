//
//  ResumeDataStore.swift
//  DynamicFeatureModule
//
//  Created by Serkan Kara on 14.01.2026.
//

import Foundation

final class ResumeDataStore {
    
    private let userDefaults = UserDefaults.standard
    private let keyPrefix = "com.dynamicfeature.resumedata."
    
    static let shared = ResumeDataStore()
    
    private init() {}
    
    func saveResumeData(_ data: Data, forModuleId moduleId: String) {
        let key = keyPrefix + moduleId
        userDefaults.set(data, forKey: key)
    }
    
    func getResumeData(forModuleId moduleId: String) -> Data? {
        let key = keyPrefix + moduleId
        return userDefaults.data(forKey: key)
    }
    
    func removeResumeData(forModuleId moduleId: String) {
        let key = keyPrefix + moduleId
        userDefaults.removeObject(forKey: key)
    }
    
    func clearAll() {
        let dictionary = userDefaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            if key.hasPrefix(keyPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}
