//
//  UserDefault.swift
//  AuthSDK
//

import Foundation

public final class DefaultGameInfoStorage: GameInfoStorage {
    
    public var packageName: String? {
        get { defaults.string(forKey: Keys.packageName) }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.packageName)
            } else {
                defaults.removeObject(forKey: Keys.packageName)
            }
        }
    }
    
    public var appVersion: String? {
        get { defaults.string(forKey: Keys.appVersion) }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.appVersion)
            } else {
                defaults.removeObject(forKey: Keys.appVersion)
            }
        }
    }
    
    public var gameUUID: String? {
        get { defaults.string(forKey: Keys.gameUUID) }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.gameUUID)
            } else {
                defaults.removeObject(forKey: Keys.gameUUID)
            }
        }
    }
    
    public var gameID: Int? {
        get {
            guard defaults.object(forKey: Keys.gameID) != nil else { return 1 }
            let gameID = defaults.integer(forKey: Keys.gameID)
            return gameID > 0 ? gameID : 1
        }
        set {
            if let newValue = newValue {
                defaults.set(newValue > 0 ? newValue : 1, forKey: Keys.gameID)
            } else {
                defaults.removeObject(forKey: Keys.gameID)
            }
        }
    }
    
    public var serverID: Int? {
        get {
            guard defaults.object(forKey: Keys.serverID) != nil else { return nil }
            return defaults.integer(forKey: Keys.serverID)
        }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.serverID)
            } else {
                defaults.removeObject(forKey: Keys.serverID)
            }
        }
    }
    
    public var serverName: String? {
        get { defaults.string(forKey: Keys.serverName) }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.serverName)
            } else {
                defaults.removeObject(forKey: Keys.serverName)
            }
        }
    }
    
    public var serverGameName: String? {
        get { defaults.string(forKey: Keys.serverGameName) }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.serverGameName)
            } else {
                defaults.removeObject(forKey: Keys.serverGameName)
            }
        }
    }
    
    public var serverGameId: String? {
        get { defaults.string(forKey: Keys.serverGameId) }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.serverGameId)
            } else {
                defaults.removeObject(forKey: Keys.serverGameId)
            }
        }
    }
    
    public var characterId: String? {
        get { defaults.string(forKey: Keys.characterId) }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Keys.characterId)
            } else {
                defaults.removeObject(forKey: Keys.characterId)
            }
        }
    }
    
    public var timeToRemindLogin: Int64 {
        get {
            Int64(defaults.integer(forKey: Keys.timeToRemindLogin))
        }
        set {
            defaults.set(Int(newValue), forKey: Keys.timeToRemindLogin)
        }
    }
    
    public func clear() {
        defaults.removeObject(forKey: Keys.packageName)
        defaults.removeObject(forKey: Keys.appVersion)
        defaults.removeObject(forKey: Keys.gameUUID)
        defaults.removeObject(forKey: Keys.gameID)
        defaults.removeObject(forKey: Keys.serverName)
        defaults.removeObject(forKey: Keys.characterId)
        defaults.removeObject(forKey: Keys.serverID)
        defaults.removeObject(forKey: Keys.timeToRemindLogin)
        defaults.removeObject(forKey: Keys.serverGameId)
        defaults.removeObject(forKey: Keys.serverGameName)
    }
    
    private let defaults: UserDefaults
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    private enum Keys {
        static let packageName = "app.packageName"
        static let appVersion = "app.version"
        static let gameID = "app.gameID"
        static let serverID = "app.serverID"
        static let serverName = "app.serverName"
        static let serverGameName = "app.serverGameName"
        static let serverGameId = "app.serverGameId"
        static let characterId = "app.characterId"
        static let gameUUID = "app.gameUUID"
        static let timeToRemindLogin = "app.timeToRemindLogin"
    }
}
