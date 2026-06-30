//
//  AuthInitModel.swift
//  AuthSDK
//

import Foundation

struct AuthInitModel {
    let platform: String
    let gameInfoModel: GameInfoModel?
    let facebookConfigModel: FacebookConfigModel?
    let googleConfigModel: GoogleConfigModel?
    let versionInfoModel: VersionInfoModel?
    let guestLoginAfterSeconds: Int64?
}

extension AuthInitModel {
    
    static func sampleInstance() -> AuthInitModel {
        return .init(
            platform: "iOS",
            gameInfoModel: GameInfoModel(gameID: 1, gameName: "S3", status: .active, serverID: 0, gameUUID: "", packageName: "", appVersion: ""),
            facebookConfigModel: FacebookConfigModel(clientId: "989017026224724",
                                                     clientToken: "d472fa0454b6ff302a4c717b277bae55"),
            googleConfigModel: GoogleConfigModel(clientId: "511211441022-p18sv5i70b87g3440kr2ld0bujg385rk.apps.googleusercontent.com",
                                                 platformUrlSchema: nil),
            versionInfoModel: VersionInfoModel(forceUpdate: true, minSdkVersion: "1.0", minAppVersion: "2.0", latestSdkVersion: "2.0", latestAppVersion: "2.0"),
            guestLoginAfterSeconds: 300
        )
    }
    
    func toResponse() throws -> AuthInitResponse? {
        guard let gameInfoModel = self.gameInfoModel else {
            return nil
        }
        guard let versionInfoModel = self.versionInfoModel else {
            //For testing when API is not ready
            let versionInfoModel = VersionInfoModel(forceUpdate: false, minSdkVersion: "1.0", minAppVersion: "0.0.9", latestSdkVersion: "2.0", latestAppVersion: "2.0")
            return AuthInitResponse(gameInfo: gameInfoModel.toResponse(), versionInfo: versionInfoModel.toResponse(), guestLoginAfterSeconds: self.guestLoginAfterSeconds)
        }
        return AuthInitResponse(gameInfo: gameInfoModel.toResponse(), versionInfo: versionInfoModel.toResponse(), guestLoginAfterSeconds: self.guestLoginAfterSeconds)
    }
    
    func toGameInfoResponse() throws -> GameInfoResponse? {
        guard let gameInfoModel = self.gameInfoModel else {
            return nil
        }
        return GameInfoResponse(gameId: gameInfoModel.gameID, gameName: gameInfoModel.gameName, status: .active)
    }
}
