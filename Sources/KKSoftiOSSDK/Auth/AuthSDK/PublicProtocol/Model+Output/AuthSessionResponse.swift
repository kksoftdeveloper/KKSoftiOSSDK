//
//  AuthSessionOut.swift
//  AuthSDK
//

import Foundation

public struct AuthSessionResponse: Codable, Equatable, Hashable {
    public let gameUUID: String?
    public let serverId: Int?
    public let accessToken: String
    public let refreshToken: String
    public let expireDate: Date
    public let isNewUser: Bool?
    public let refreshExpireDate: Date?
    public let userBlocked: Bool?
    public let gameBlocked: Bool?
    public let serverBlocked: Bool?
    public let loginReminderResponse: LoginReminderResponse?
    
    private enum CodingKeys: String, CodingKey {
        case gameUUID = "gameUID"
        case serverId = "serverId"
        case accessToken = "accessToken"
        case refreshToken = "refreshToken"
        case expireDate = "expireDate"
        case refreshExpireDate = "refreshExpireDate"
        case isNewUser = "isNewUser"
        case userBlocked = "userBlocked"
        case gameBlocked = "gameBlocked"
        case serverBlocked = "serverBlocked"
        case loginReminderResponse = "loginReminderResponse"
    }
}

public struct LoginReminderResponse: Codable, Equatable, Hashable {
    public let loginAfterSeconds: Int64
    public let isGuestUser: Bool
    public let isNewUser: Bool?
}

public extension AuthSessionResponse {
    func copy(
        gameUUID: String?                = nil,
        serverId: Int?                   = nil,
        accessToken: String?             = nil,
        refreshToken: String?            = nil,
        expireDate: Date?                = nil,
        isNewUser: Bool?                 = nil,
        refreshExpireDate: Date?         = nil,
        userBlocked: Bool?                = nil,
        gameBlocked: Bool?                = nil,
        serverBlocked: Bool?              = nil,
        loginReminderResponse: LoginReminderResponse? = nil
    ) -> AuthSessionResponse {
        AuthSessionResponse(
            gameUUID: gameUUID               ?? self.gameUUID,
            serverId: serverId               ?? self.serverId,
            accessToken: accessToken         ?? self.accessToken,
            refreshToken: refreshToken       ?? self.refreshToken,
            expireDate: expireDate           ?? self.expireDate,
            isNewUser: isNewUser             ?? self.isNewUser,
            refreshExpireDate: refreshExpireDate ?? self.refreshExpireDate,
            userBlocked: userBlocked          ?? self.userBlocked,
            gameBlocked: gameBlocked          ?? self.gameBlocked,
            serverBlocked: serverBlocked      ?? self.serverBlocked,
            loginReminderResponse: loginReminderResponse ?? self.loginReminderResponse
        )
    }
}
