//
//  AuthSessionResponse.swift
//  PaymentSDK
//
//  Created by X on 11/4/25.
//

import Foundation

public struct AuthSessionOutput: Codable, Equatable, Hashable {
    public let gameUUID: String
    public let accessToken: String
    public let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case gameUUID = "gameUID"
        case accessToken = "accessToken"
        case refreshToken = "refreshToken"
    }
}
