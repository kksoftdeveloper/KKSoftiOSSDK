//
//  GameInfoResponse.swift
//  KKSoftiOSSDK
//
//  Created by KKSOFT on 10/6/26.
//

import Foundation


public struct GameInfoResponse: Codable {
    
    let gameId: Int
    let gameName: String
    let status: GameStatusDTO
    
    private enum CodingKeys: String, CodingKey {
        case gameId = "gameId"
        case gameName = "gameName"
        case status = "status"
    }
    
    enum GameStatusDTO: String, Codable {
        case active = "ACTIVE"
        case inactive = "INACTIVE"
    }
}

extension GameInfoResponse.GameStatusDTO {
    func toModel() -> GameStatus {
        switch self {
        case .active:
            return .active
        case .inactive:
            return .inactive
        }
    }
}

extension GameInfoResponse {
    
    func toModel() -> GameInfoModel {
        return GameInfoModel(
            gameID: gameId,
            gameName: "Demo",
            status: status.toModel(),
            serverID: 1,
            gameUUID: "12",
            packageName: "wqqw",
            appVersion: "1.0.0"
        )
    }
}
