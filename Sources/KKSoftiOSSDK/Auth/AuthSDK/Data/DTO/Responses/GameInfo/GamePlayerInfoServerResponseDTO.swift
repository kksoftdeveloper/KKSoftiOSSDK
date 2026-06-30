//
//  GamePlayerInfoServerResponseDTO.swift
//  AuthSDK
//
//  Created by X on 5/8/25.
//

import Foundation

typealias GamePlayerInfoServerResponse = APIResponse<GamePlayerInfoServerResponseDTO>

struct GamePlayerInfoServerResponseDTO: Decodable {
    
    let gameUUID: String
    
    private enum CodingKeys: String, CodingKey {
        case gameUUID = "gameUId"
    }
}
