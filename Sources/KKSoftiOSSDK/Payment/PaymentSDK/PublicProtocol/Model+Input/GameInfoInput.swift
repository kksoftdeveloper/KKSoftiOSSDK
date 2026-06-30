//
//  GameInfoInput.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

public struct GameInfoInput: Codable, Equatable, Hashable {
    public let gameUUID: String
    public let gameID: Int
    public let gameName: String
    public let serverID: Int
}
