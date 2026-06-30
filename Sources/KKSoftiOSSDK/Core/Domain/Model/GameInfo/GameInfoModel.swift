//
//  GameInfoModel.swift
//  AuthSDK
//

import Foundation

struct GameInfoModel {
    let gameID: Int
    let gameName: String
    let status: GameStatus
    let serverID: Int
    let gameUUID: String
    let packageName: String
    let appVersion: String
}

extension GameInfoModel {
    func toOutput() -> GameInfoOutput {
        return GameInfoOutput(gameId: gameID,
                              gameName: gameName,
                              status: status.rawValue)
    }
    
    func toResponse() -> GameInfoResponse {
        return GameInfoResponse(gameId: gameID, gameName: gameName, status: .active)
        }
}
