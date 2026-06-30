//
//  GameInfo.swift
//  AuthSDK
//

import Foundation


struct GameInfoServerResponseDTO: Decodable {
    
    let gameId: Int
    let gameName: String
    let status: String?
}

extension GameInfoServerResponseDTO {
    func toGameStatus() -> GameStatus {
        switch self.status?.uppercased() {
        case GameStatus.active.rawValue.uppercased():
            return .active
        case GameStatus.inactive.rawValue.uppercased():
            return .inactive
        case GameStatus.open.rawValue.uppercased():
            return .open
        default:
            return .inactive
        }
    }
}

extension GameInfoServerResponseDTO {
    
    func toModel() -> GameInfoModel {
        return GameInfoModel(
            gameID: gameId > 0 ? gameId : 1, gameName: gameName, status: toGameStatus(),
            serverID: 0,
            gameUUID: "",
            packageName: "",
            appVersion: ""
        )
    }
}
