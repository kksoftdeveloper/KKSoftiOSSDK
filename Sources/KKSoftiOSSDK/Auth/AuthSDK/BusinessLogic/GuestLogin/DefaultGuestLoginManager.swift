//
//  UsernamePasswordLoginManager.swift
//  AuthSDK
//

import Foundation
import Combine

final class DefaultGuestLoginManager: GuestLoginManager, DeviceIdentifiable, SDKInfo, LoginAnalytics {
    
    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var gamePlayerStorage: GamePlayerStorage
    private var sessionManager: SessionManager
    private var signature: Signature
    public var deviceSecretKey: String { return Environment.deviceSecretKey }
    
    init(authAPIClient: AuthAPIClient,
         gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage(),
         sessionManager: SessionManager = KeyChainSessionManager(),
         gamePlayerStorage: GamePlayerStorage = GamePlayerKeychainStorage(),
         signature: Signature = SHA256Signature()
    ) {
        self.authAPIClient = authAPIClient
        self.gameInfoStorage = gameInfoStorage
        self.sessionManager = sessionManager
        self.gamePlayerStorage = gamePlayerStorage
        self.signature = signature
    }

    func login() -> AnyPublisher<AuthSessionResponse, Error> {
        
        guard let gameId = gameInfoStorage.gameID else {
            BaseAnalytics.track(event: self.guestLogin, properties: [self.failure: AuthErrorResponse.appNotConfiguredGame().message])
            return Fail(error: AuthErrorResponse.appNotConfiguredGame())
                .eraseToAnyPublisher()
        }
        
        guard let appVersion = gameInfoStorage.appVersion, !appVersion.isEmpty else {
            BaseAnalytics.track(event: self.guestLogin, properties: [self.failure: AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized())
                .eraseToAnyPublisher()
        }
        
        let serverId = gameInfoStorage.serverID
        
        guard let sign = try? signature.sign(type: "guest") else {
            BaseAnalytics.track(event: self.guestLogin, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
            return Fail(error: AuthErrorResponse.sdkSignatureError())
                .eraseToAnyPublisher()
        }
        
        let body = GuestLoginRequestBody(
            deviceId: deviceID,
            gameId: gameId,
            serverId: serverId,
            platform: platform,
            sdkVersion: versionName,
            appVersion: appVersion,
            sign: sign
        )
        
        return authAPIClient.login(header: nil, body: body.toDictionary())
            .tryMap { sessionDTO in
                let timeToRemindLoginInSeconds = self.gameInfoStorage.timeToRemindLogin
                let isGuestUser = sessionDTO.data.isNewUser != nil
                let isNewuser = sessionDTO.data.isNewUser == true
                let model = sessionDTO.data.toModel(
                    loginAfterSeconds: timeToRemindLoginInSeconds,
                    isNewUser: isNewuser,
                    isGuestUser: isGuestUser
                )
                self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                
                try? self.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                
                try? self.gamePlayerStorage.saveIsGuestUser(isGuestUser)
                
                try? self.gamePlayerStorage.saveIsNewUser(isNewuser)
                
                try? self.gamePlayerStorage.savePhoneNumber("")
                
                return model.toResponse()
            }.eraseToAnyPublisher()
    }
    
    func getAuthSesssion() -> AnyPublisher<AuthSessionResponse, Error> {
        do {
            debugPrint("GetAuthSession: entering")
            guard let authSessionResponse = try? sessionManager.getSession()?.toResponse() else {
                BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
                throw AuthErrorResponse.unauthenticated()
            }

            guard let gameId = self.gameInfoStorage.gameID else {
                throw AuthErrorResponse.appNotConfiguredGame()
            }

            guard let serverId = self.gameInfoStorage.serverID else {
                throw AuthErrorResponse.appNotConfiguredGameServer()
            }
//            let header: [String:String] = ["Authorization": "Bearer \(authSessionResponse.accessToken)"]
            return authAPIClient
                .getCharacter(header: [:], gameId: gameId, serverId: serverId)
                .handleEvents(
                    receiveSubscription: { _ in debugPrint("GetAuthSession: getCharacter subscribed") },
                    receiveOutput: { resp in debugPrint("GetAuthSession: getCharacter value -> \(resp)") },
                    receiveCompletion: { debugPrint("GetAuthSession: getCharacter completion = \($0)") },
                    receiveCancel: { debugPrint("GetAuthSession: getCharacter cancelled") }
                )
                .flatMap { gameUidResponse in
                    debugPrint("GetAuthSession: gameUidResponse -> \(gameUidResponse)")
                    debugPrint("GetAuthSession: gameInfoStorage -> \(String(describing: self.gameInfoStorage.gameUUID))")
                    debugPrint("GetAuthSession: gameInfoStorage -> \(String(describing: gameUidResponse.data.characterId))")
                    if let characterId = gameUidResponse.data.characterId {
                        debugPrint("GetAuthSession: success, returning session with characterId \(characterId)")
                        self.gameInfoStorage.characterId = characterId
                    }
                    if let gameUUID = gameUidResponse.data.gameUUID, self.gameInfoStorage.gameUUID?.contains(gameUUID) == true {
                        BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.success: "Get Auth Session Successfully"])
                        debugPrint("GetAuthSession: success, returning session with gameUUID \(gameUUID)")
                        return Just(authSessionResponse.copy(gameUUID: gameUUID))
                            .handleEvents(receiveOutput: { session in
                                AuthTracking.handleRetentionD1IfNeeded(session: session)
                            })
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    } else {
                        let err = AuthErrorResponse.unauthenticated()
                        BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: err.message])
                        debugPrint("GetAuthSession: gameUUID mismatch or nil -> failing unauthenticated")
                        return Fail(error: err).eraseToAnyPublisher()
                    }
                }
                .handleEvents(
                    receiveSubscription: { _ in debugPrint("GetAuthSession: flatten subscribed") },
                    receiveOutput: { _ in debugPrint("GetAuthSession: output session") },
                    receiveCompletion: { debugPrint("GetAuthSession: completion = \($0)") },
                    receiveCancel: { debugPrint("GetAuthSession: cancelled") }
                )
                .eraseToAnyPublisher()

        } catch {
            debugPrint("GetAuthSession: early throw -> \(error)")
            BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
    }
    
    func logout() -> AnyPublisher<DatalessServerResponse, Error> {
        do {
            BaseAnalytics.track(event: self.logout)
            return authAPIClient.logout()
                .tryMap { logoutServerResponse in
                    try self.sessionManager.clear()
                    try self.gamePlayerStorage.clear()
                    self.gameInfoStorage.clear()
                    return logoutServerResponse.toModel().toResponse()
            }
            .eraseToAnyPublisher()
        } catch {
            BaseAnalytics.track(event: self.logout, properties: [self.failure: error.localizedDescription])
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
    }
    
    func getPhoneNumber() throws -> String? {
        try gamePlayerStorage.getPhoneNumber()
    }
    
    func getServerId() -> Int? {
        gameInfoStorage.serverID
    }
    
    func getGameId() -> Int? {
        gameInfoStorage.gameID
    }
    
    func isGuestUser() -> Bool {
        do {
            return try gamePlayerStorage.getIsGuestUser()
        } catch {
            debugPrint("Failed to get guest user status: \(error)")
            return false
        }
    }
}

struct GuestLoginRequestBody: Encodable {
    let provider: String = "guest"
    let deviceId: String
    let gameId: Int
    let serverId: Int?
    let platform: String
    let sdkVersion: String
    let appVersion: String
    let sign: String
    
    private enum CodingKeys: String, CodingKey {
        case provider = "type"
        case deviceId = "deviceId"
        case gameId = "gameId"
        case serverId = "serverId"
        case platform = "platform"
        case sdkVersion = "sdkVersion"
        case appVersion = "appVersion"
        case sign
    }
}

struct GuestLoginRequestHeader: Encodable {
    
    let accessToken: String?
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "accessToken"
    }
}
