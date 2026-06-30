//
//  DefaultGameServerInfoManager.swift
//  AuthSDK
//

import Foundation
import Combine

final class DefaultGameServerInfoManager : GameServerInfoManager, DeviceIdentifiable, SDKInfo, GameInfoAnalytics {
    
    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var signature: Signature
    private var sessionManager: SessionManager
    public var deviceSecretKey: String { return Environment.deviceSecretKey }
    
    init(authAPIClient: AuthAPIClient,
         gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage(),
         signature: Signature = SHA256Signature(),
         sessionManager: SessionManager = KeyChainSessionManager()
    ) {
        self.authAPIClient = authAPIClient
        self.gameInfoStorage = gameInfoStorage
        self.signature = signature
        self.sessionManager = sessionManager
    }
    
    func getGameInfo() -> AnyPublisher<GameInfoResponse, any Error> {
        guard let packageName = self.gameInfoStorage.packageName, let appVersion = gameInfoStorage.appVersion else {
            BaseAnalytics.track(event: self.getGameInfo, properties: [self.failure : AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
        }
        
        let timeStamp = Int(Date().timeIntervalSince1970)
        
        guard let signature = try? self.signature.sign(timestampInSeconds: timeStamp) else {
            BaseAnalytics.track(event: self.getGameInfo, properties: [self.failure : AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
        }
     
        let body = InitSDKRequestBody(
            packageName: packageName,
            deviceId: deviceID,
            platform: platform,
            sdkVersion: versionName,
            appVersion: appVersion,
            timestamp: timeStamp,
            sign: signature
        )
        
        BaseAnalytics.track(event: self.getGameInfo, properties: [self.request : body.toDictionary().toMixpanelType()])
        
        return authAPIClient.initSDK(body: body)
            .tryMap { resDTO in
                let model = resDTO.data.toModel()
                self.gameInfoStorage.gameID = model.gameInfoModel?.gameID ?? 1
                
                let infoDictionary = Bundle.main.infoDictionary
                if let fbClientID = [model.facebookConfigModel?.clientId, infoDictionary?["FacebookAppID"] as? String]
                    .compactMap({ $0?.configuredValue })
                    .first {
                    try SensitiveDataManager.shared.set(fbClientID, for: .facebookClientID)
                }
                if let fbSecretClient = [model.facebookConfigModel?.clientToken, infoDictionary?["FacebookClientToken"] as? String]
                    .compactMap({ $0?.configuredValue })
                    .first {
                    try SensitiveDataManager.shared.set(fbSecretClient, for: .facebookClientSecret)
                }
                if let ggClientID = [model.googleConfigModel?.clientId, infoDictionary?["GIDClientID"] as? String]
                    .compactMap({ $0?.configuredValue })
                    .first {
                    try SensitiveDataManager.shared.set(ggClientID, for: .googleClientID)
                }
                if let ggURLSchema = [model.googleConfigModel?.platformUrlSchema, infoDictionary?["GIDReversedClientID"] as? String]
                    .compactMap({ $0?.configuredValue })
                    .first {
                    try SensitiveDataManager.shared.set(ggURLSchema, for: .googleURLSchema)
                }
                guard let response = try resDTO.data.toModel().toGameInfoResponse() else {
                    BaseAnalytics.track(event: self.getGameInfo, properties: [self.failure : AuthErrorResponse.appNotFound().message])
                    throw AuthErrorResponse.appNotFound()
                }
                return response
            }
            .eraseToAnyPublisher()
    }
    
    func getGameServers() -> AnyPublisher<[GameServerInfoResponse], any Error> {
        guard let gameID = gameInfoStorage.gameID else {
            BaseAnalytics.track(event: self.getGameServers, properties: [self.failure : AuthErrorResponse.appNotConfiguredGame().message])
            return Fail(error: AuthErrorResponse.appNotConfiguredGame()).eraseToAnyPublisher()
        }

        BaseAnalytics.track(event: self.getGameServers)
        return authAPIClient.getGameServers(gameId: gameID)
            .tryMap { resDTO in
                resDTO.data.map { dto in
                    dto.toModel().toResponse()
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getAuthenticatedGameServers() -> AnyPublisher<[GameServerInfoResponse], any Error> {
        guard let packageName = self.gameInfoStorage.packageName, let appVersion = gameInfoStorage.appVersion else {
            BaseAnalytics.track(event: self.getGameServers, properties: [self.failure : AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
        }
        guard let gameID = gameInfoStorage.gameID else {
            BaseAnalytics.track(event: self.getGameServers, properties: [self.failure : AuthErrorResponse.appNotConfiguredGame().message])
            return Fail(error: AuthErrorResponse.appNotConfiguredGame()).eraseToAnyPublisher()
        }
        guard let _ = try? sessionManager.getSession()?.accessToken else {
            BaseAnalytics.track(event: self.getGameServers, properties: [self.failure : AuthErrorResponse.unauthenticated().message])
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
//        let header = ["Authorization": "Bearer \(accessToken)"]
        
        let body = GetGameServerInfoRequestBody(
            packageName: packageName,
            platform: platform,
            sdkVersion: versionName,
            appVersion: appVersion
        )
        BaseAnalytics.track(event: self.getGameServers, properties: [self.request : body.toDictionary().toMixpanelType()])
        return authAPIClient.getGameServers(gameId: gameID, header: [:], body: body.toDictionary() ?? [:])
            .tryMap { resDTO in
                resDTO.data.map { dto in
                    dto.toModel().toResponse()
                }
            }
            .eraseToAnyPublisher()
    }

    func updateGameServer(selectedServerId: Int, selectedServerName: String) -> AnyPublisher<GameUUID, any Error> {
//        var gameServerModel = selectedServer.toModel()
        guard let _ = try? sessionManager.getSession()?.accessToken else {
            BaseAnalytics.track(event: self.updateGameServer, properties: [self.failure : AuthErrorResponse.unauthenticated().message])
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
//        let header = ["Authorization": "Bearer \(accessToken)"]
        guard let gameID = gameInfoStorage.gameID else {
            BaseAnalytics.track(event: self.updateGameServer, properties: [self.failure : AuthErrorResponse.appNotConfiguredGame().message])
            return Fail(error: AuthErrorResponse.appNotConfiguredGame()).eraseToAnyPublisher()
        }
        return authAPIClient.updateGameServers(gameId: gameID, serverId: selectedServerId, header: [:])
            .tryMap { resDTO in
                self.gameInfoStorage.serverID = selectedServerId
                self.gameInfoStorage.serverName = selectedServerName

                let gameUUID: String = resDTO.data.gameUUID
                self.gameInfoStorage.gameUUID = gameUUID
                let refreshedSession = try? self.sessionManager.getSession()?.copy(
                    gameUUID: gameUUID
                )
                if let refreshedSession = refreshedSession {
                    try? self.sessionManager.saveSession(authSession: refreshedSession, isRefreshToken: false)
                }
                
                return gameUUID
            }
            .eraseToAnyPublisher()
    }
}

struct GetGameServerInfoRequestBody: Encodable {
    let packageName: String
    let platform: String
    let sdkVersion: String
    let appVersion: String
}
