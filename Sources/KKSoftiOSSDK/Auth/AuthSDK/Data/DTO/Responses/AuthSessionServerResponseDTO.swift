//
//  OurAuthResponse.swift
//  AuthSDK
//

import Foundation

typealias AuthSessionServerResponse = APIResponse<AuthSessionServerDTO>

struct AuthSessionServerDTO: Decodable {
    let gameUUID: String?
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

extension AuthSessionServerDTO {
    func toModel(
        loginAfterSeconds: Int64 = 0,
        isNewUser: Bool? = nil,
        isGuestUser: Bool? = nil
    ) -> AuthSessionModel {
        let gameUId: String? = {
            guard let uuid = self.gameUUID,
                  !uuid.localizedCaseInsensitiveContains("null")
            else { return nil }
            return uuid
        }()
        var loginReminder: LoginReminderModel?
        if let isNewUser = isNewUser,
           let isGuestUser = isGuestUser,
           loginAfterSeconds != 0 {
            loginReminder = LoginReminderModel(
                loginAfterSeconds: loginAfterSeconds,
                isGuestUser: isGuestUser,
                isNewUser: isNewUser
            )
        }
        return AuthSessionModel(
            gameUUID: gameUId,
            serverId: serverId,
            accessToken: self.accessToken,
            refreshToken: self.refreshToken,
            expireDate: self.expireDate.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX") ?? Date(),
            isNewUser: self.isNewUser,
            refreshExpireDate: self.refreshExpireDate?.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"),
            userBlocked: self.userBlocked,
            gameBlocked: self.gameBlocked,
            serverBlocked: self.serverBlocked,
            loginReminder: loginReminder
        )
    }
}
