/*
 Copyright (c) 2017 Oliver Roehrdanz
 Copyright (c) 2017 Matteo Sassano
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 */

import UIKit

class DataStorage: NSObject {
    
    let storagePath = "storage"
    let agentIdStorage = "agentIDStorage"
    let hostStorage = "hostStorage"
    let monitorStorage = "monitorStorage"
    

    func loadUsecases() -> [String] {
        if let encodedObj = UserDefaults.standard.object(forKey: storagePath) as? NSData {
            if let loadedData = NSKeyedUnarchiver.unarchiveObject(with: encodedObj as Data) as? [String] {
                return loadedData
            }
        }
        return []
    }
    
    func storeHostUrl(url: String) {
        let encodedObj = NSKeyedArchiver.archivedData(withRootObject: url)
        UserDefaults.standard.set(encodedObj, forKey: hostStorage)
    }
    
    func loadHostUrl() -> String? {
        if let encodedObj = UserDefaults.standard.object(forKey: hostStorage) as? NSData {
            if let loadedData = NSKeyedUnarchiver.unarchiveObject(with: encodedObj as Data) as? String {
                return loadedData
            }
        }
        return nil
    }
    
    func storeMonitorUrl(url: String) {
        let encodedObj = NSKeyedArchiver.archivedData(withRootObject: url)
        UserDefaults.standard.set(encodedObj, forKey: monitorStorage)
    }
    
    func loadMonitorUrl() -> String? {
        if let encodedObj = UserDefaults.standard.object(forKey: monitorStorage) as? NSData {
            if let loadedData = NSKeyedUnarchiver.unarchiveObject(with: encodedObj as Data) as? String {
                return loadedData
            }
        }
        return nil
    }
    
    func storeAgentId(id: UInt64) {
        let encodedObj = NSKeyedArchiver.archivedData(withRootObject: id)
        UserDefaults.standard.set(encodedObj, forKey: agentIdStorage)
    }
    
    func loadAgentId() -> UInt64? {
        if let encodedObj = UserDefaults.standard.object(forKey: agentIdStorage) as? NSData {
            if let loadedData = NSKeyedUnarchiver.unarchiveObject(with: encodedObj as Data) as? UInt64 {
                return loadedData
            }
        }
        return nil
    }
    
    func storeUsecases(storageData: [String]) {
        let encodedObj = NSKeyedArchiver.archivedData(withRootObject: storageData)
        UserDefaults.standard.set(encodedObj, forKey: storagePath)
    }
    
    func clearStorage() {
        let encodedObj = NSKeyedArchiver.archivedData(withRootObject: [])
        UserDefaults.standard.set(encodedObj, forKey: storagePath)
    }
    
}
