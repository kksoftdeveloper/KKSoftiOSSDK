//
//  DefaultAppInfoStorage.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

final class DefaultAppInfoStorage: AppInfoStorage {
    
    var packageName: String? {
        get { defaults.string(forKey: Keys.packageName) }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.packageName)
            } else {
                defaults.removeObject(forKey: Keys.packageName)
            }
        }
    }
    
    var appVersion: String? {
        get { defaults.string(forKey: Keys.appVersion) }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.appVersion)
            } else {
                defaults.removeObject(forKey: Keys.appVersion)
            }
        }
    }
    
    func clear() {
        defaults.removeObject(forKey: Keys.packageName)
        defaults.removeObject(forKey: Keys.appVersion)
    }
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    private enum Keys {
        static let packageName = "app.packageName"
        static let appVersion = "app.version"
    }
}
