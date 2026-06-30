//
//  AuthSession.swift
//  AuthSDK
//

import Foundation


public struct AuthSessionModel {
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
    public let loginReminder: LoginReminderModel?
    
    public init(
        gameUUID: String?,
        serverId: Int? = nil,
        accessToken: String,
        refreshToken: String,
        expireDate: Date,
        isNewUser: Bool? = nil,
        refreshExpireDate: Date? = nil,
        userBlocked: Bool? = nil,
        gameBlocked: Bool? = nil,
        serverBlocked: Bool? = nil,
        loginReminder: LoginReminderModel? = nil
    ) {
        self.gameUUID = gameUUID
        self.serverId = serverId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expireDate = expireDate
        self.isNewUser = isNewUser
        self.refreshExpireDate = refreshExpireDate
        self.userBlocked = userBlocked
        self.gameBlocked = gameBlocked
        self.serverBlocked = serverBlocked
        self.loginReminder = loginReminder
    }
}

extension AuthSessionModel {
    public func copy(
        gameUUID: String? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        expireDate: Date? = nil,
        isNewUser: Bool? = nil,
        refreshExpireDate: Date? = nil,
        userBlocked: Bool? = nil,
        gameBlocked: Bool? = nil,
        serverBlocked: Bool? = nil,
        loginReminder: LoginReminderModel? = nil
    ) -> AuthSessionModel {
        return AuthSessionModel(
            gameUUID:       gameUUID       ?? self.gameUUID,
            serverId:       serverId       ?? self.serverId,
            accessToken:    accessToken    ?? self.accessToken,
            refreshToken:   refreshToken   ?? self.refreshToken,
            expireDate:     expireDate     ?? self.expireDate,
            isNewUser:      isNewUser      ?? self.isNewUser,
            refreshExpireDate: refreshExpireDate ?? self.refreshExpireDate,
            userBlocked: userBlocked        ?? self.userBlocked,
            gameBlocked: gameBlocked        ?? self.gameBlocked,
            serverBlocked: serverBlocked    ?? self.serverBlocked,
            loginReminder:  loginReminder  ?? self.loginReminder
        )
    }
    
    func toResponse() -> AuthSessionResponse {
        return AuthSessionResponse(
            gameUUID: self.gameUUID,
            serverId: self.serverId,
            accessToken: self.accessToken,
            refreshToken: self.refreshToken,
            expireDate: self.expireDate,
            isNewUser: self.isNewUser,
            refreshExpireDate: self.refreshExpireDate,
            userBlocked: self.userBlocked,
            gameBlocked: self.gameBlocked,
            serverBlocked: self.serverBlocked,
            loginReminderResponse: self.loginReminder?.toResponse()
        )
    }

    static func sampleInstance() -> AuthSessionModel {
        return .init(
            gameUUID: "1001",
            serverId:  75,
            accessToken: "access token",
            refreshToken: "refresh token",
            expireDate: Date(),
            isNewUser: nil,
            refreshExpireDate: nil,
            userBlocked: false,
            gameBlocked: false,
            serverBlocked: false,
            loginReminder: nil
        )
    }
}

extension LoginReminderResponse {
    func toModel() -> LoginReminderModel {
        return .init(
            loginAfterSeconds: self.loginAfterSeconds, isGuestUser: isGuestUser, isNewUser: isNewUser
        )
    }
}

extension AuthSessionResponse {
    func toModel() -> AuthSessionModel {
        var loginReminder: LoginReminderModel?
        if let loginReminderResponse = self.loginReminderResponse {
            loginReminder = loginReminderResponse.toModel()
        }
        
        return .init(
            gameUUID: self.gameUUID,
            serverId: self.serverId,
            accessToken: self.accessToken,
            refreshToken: self.refreshToken,
            expireDate: self.expireDate,
            isNewUser: self.isNewUser,
            refreshExpireDate: self.refreshExpireDate,
            userBlocked: self.userBlocked,
            gameBlocked: self.gameBlocked,
            serverBlocked: self.serverBlocked,
            loginReminder: loginReminder
        )
    }
}
