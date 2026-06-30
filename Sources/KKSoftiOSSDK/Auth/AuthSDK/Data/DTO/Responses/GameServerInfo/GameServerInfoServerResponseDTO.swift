//
//  GameServerResponseDTO.swift
//  AuthSDK
//

import Foundation

typealias GameServerInfoServerResponse = APIResponse<[GameServerInfoServerResponseDTO]>

struct GameServerInfoServerResponseDTO: Decodable {
    
    let serverId: Int
    let serverName: String
    let serverClientId: String?
    let serverClientName: String?
    let status: String
}

extension GameServerInfoServerResponseDTO {
    func toGameServerStatus() -> GameServerStatus {
        switch self.status.uppercased() {
        case GameServerStatus.online.rawValue.uppercased():
            return .online
        default :
            return .offline
        }
    }
}

extension GameServerInfoServerResponseDTO {
    
    func toModel() -> GameServerInfoModel {
        return GameServerInfoModel(
            serverId: serverId, serverName: serverName, serverClientId: serverClientId, serverClientName: serverClientName, status: toGameServerStatus()
        )
    }
}
