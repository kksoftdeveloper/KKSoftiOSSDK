//
//  GameInfoManager.swift
//  AuthSDK
//

import Foundation

protocol GameInfoStorage {
    var packageName: String? { get set }
    var appVersion: String? { get set }
    var gameUUID: String? { get set }
    var gameID: Int? { get set }
    var serverID: Int? { get set }
    var serverName: String? { get set }
    var serverGameId: String? { get set }
    var serverGameName: String? { get set }
    var characterId: String? { get set }
    var timeToRemindLogin: Int64 { get set }
    
    func clear()
}
