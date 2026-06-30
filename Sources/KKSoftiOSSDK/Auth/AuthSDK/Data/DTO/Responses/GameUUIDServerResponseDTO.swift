//
//  File.swift
//  AuthSDK
//
//  Created by Admin on 11/3/25.
//

import Foundation

typealias GameUUIDServerResponse = APIResponse<GameUUIDServerResponseDTO>

struct GameUUIDServerResponseDTO: Decodable {
    let gameUUID: String?
    let characterId: String?
    
    private enum CodingKeys: String, CodingKey {
        case gameUUID = "gameUId"
        case characterId = "characterId"
    }
}

extension GameUUIDServerResponseDTO {
    func toModel() -> GameUUIDModel {
        return GameUUIDModel(gameUUID: gameUUID ?? "",
                             characterId: characterId ?? "")
    }
}
