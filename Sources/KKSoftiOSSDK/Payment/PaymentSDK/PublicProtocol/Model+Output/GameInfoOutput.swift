//
//  GameInfoOutput.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

public struct GameInfoOutput: Codable {
    public let gameId: Int
    public let gameName: String
    public let status: String
    
    private enum CodingKeys: String, CodingKey {
        case gameId = "gameId"
        case gameName = "gameName"
        case status = "status"
    }
}
