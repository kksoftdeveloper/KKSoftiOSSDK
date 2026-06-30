//
//  AuthSessionServerResponseDTO.swift
//  PaymentSDK
//
//  Created by X on 11/4/25.
//

import Foundation

typealias PaymentSessionServerResponse = APIResponse<PaymentSessionServerDTO>

struct PaymentSessionServerDTO: Decodable {
    let gameUUID: String
    let accessToken: String
    let refreshToken: String
    let expireDate: String
    let refreshExpireDate: String?
    let isNewUser: Bool?
    let serverId: Int?
    let userBlocked: Bool?
    let gameBlocked: Bool?
    let serverBlocked: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case gameUUID = "gameUId"
        case serverId = "serverId"
        case accessToken = "accessToken"
        case refreshToken = "refreshToken"
        case expireDate = "expireDate"
        case refreshExpireDate = "refreshExpireDate"
        case isNewUser = "isNewUser"
        case userBlocked = "userBlocked"
        case gameBlocked = "gameBlocked"
        case serverBlocked = "serverBlocked"
    }
}

extension PaymentSessionServerDTO {
    func toModel(
    ) -> AuthSessionModel {
        return AuthSessionModel(
            gameUUID: gameUUID,
            accessToken: self.accessToken,
            refreshToken: self.refreshToken,
            expireDate: Date()
        )
    }
}
