//
//  Model+Input.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

public struct AuthSessionInput: Codable, Equatable, Hashable {
    public let gameUUID: String
    public let accessToken: String
    public let refreshToken: String
    private enum CodingKeys: String, CodingKey {
        case gameUUID = "gameUId"
        case accessToken = "accessToken"
        case refreshToken = "refreshToken"
    }
}
