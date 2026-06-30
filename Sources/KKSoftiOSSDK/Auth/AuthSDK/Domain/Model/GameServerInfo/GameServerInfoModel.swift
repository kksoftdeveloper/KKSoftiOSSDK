//
//  GameInfoModel.swift
//  AuthSDK
//

import Foundation

struct GameServerInfoModel {
    let serverId: Int
    let serverName: String
    let serverClientId: String?
    let serverClientName: String?
    let status: GameServerStatus
}

extension GameServerInfoModel {
    func toResponse() -> GameServerInfoResponse {
        return GameServerInfoResponse(serverId: serverId, serverName: serverName, serverClientId: serverClientId, serverClientName: serverClientName, serverStatus: status.toResponse())
    }
}

extension GameServerStatus {
    
    func toResponse() -> ServerStatusResponse {
        switch self {
        case .online:
            return .online
        case .offline:
            return .offline
        case .unknown:
            return .unknown
        }
    }
    
}
