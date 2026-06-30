//
//  UsernamePasswordLoginManager.swift
//  AuthSDK
//

import Foundation
import Combine

final class EmailPasswordLoginManager: UsernamePasswordLoginManager, DeviceIdentifiable, SDKInfo, LoginAnalytics {
    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var gamePlayerStorage: GamePlayerStorage
    private var sessionManager: SessionManager
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    init(authAPIClient: AuthAPIClient,
         sessionManager: SessionManager = KeyChainSessionManager(),
         gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage(),
         gamePlayerStorage: GamePlayerStorage = GamePlayerKeychainStorage()
    ) {
        self.authAPIClient = authAPIClient
        self.gameInfoStorage = gameInfoStorage
        self.sessionManager = sessionManager
        self.gamePlayerStorage = gamePlayerStorage
    }

    func login(phoneNumber: String, password: String) -> AnyPublisher<AuthSessionResponse, Error> {
        do {
            let _ = try EmailLoginParameters(email: phoneNumber, password: password).validate()
            
            guard let gameId = gameInfoStorage.gameID else {
                return Fail(error: AuthErrorResponse.appNotConfiguredGame())
                    .eraseToAnyPublisher()
            }
            
            guard let appVersion = gameInfoStorage.appVersion, !appVersion.isEmpty else {
                return Fail(error: AuthErrorResponse.sdkNotInitialized())
                    .eraseToAnyPublisher()
            }
            
            guard let serverID = gameInfoStorage.serverID, !appVersion.isEmpty else {
                return Fail(error: AuthErrorResponse.appNotConfiguredGameServer())
                    .eraseToAnyPublisher()
            }
            
            let body = EmailLoginRequestBody(
                email: phoneNumber,
                password: password,
                deviceId: deviceID,
                gameId: gameId,
                serverId: serverID,
                platform: platform,
                sdkVersion: versionName,
                appVersion: appVersion
            )
            
            return authAPIClient.login(header: nil, body: body.toDictionary().toMixpanelType())
                .map { sessionDTO in
                    self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                    let model = sessionDTO.data.toModel()
                    try? self.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                    try? self.gamePlayerStorage.savePhoneNumber("")
                    try? self.gamePlayerStorage.saveIsGuestUser(false)
                    return model.toResponse()
                }
                .flatMap { sessionResponse -> AnyPublisher<AuthSessionResponse, Error> in
                    self.getCharacter(gameId: gameId, serverId: serverID)
                        .map { sessionResponse }
                        .catch { _ in Just(sessionResponse).setFailureType(to: Error.self) }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            
        } catch {
            return Fail(error: AuthErrorModel.matchError())
                .eraseToAnyPublisher()
        }
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
    
    func getCharacter(gameId: Int, serverId: Int) -> AnyPublisher<Void, Error> {
        return authAPIClient
            .getCharacter(header: [:], gameId: gameId, serverId: serverId)
            .map { gameUidResponse in
                if let characterId = gameUidResponse.data.characterId {
                    self.gameInfoStorage.characterId = characterId
                }
                return ()
            }
            .eraseToAnyPublisher()
    }
}

struct EmailLoginRequestBody: Encodable {
    let provider: String = "email"
    let email: String
    let password: String
    let deviceId: String
    let gameId: Int
    let serverId: Int
    let platform: String
    let sdkVersion: String
    let appVersion: String
    
    private enum CodingKeys: String, CodingKey {
        case provider = "provider"
        case email = "email"
        case password = "password"
        case deviceId = "deviceId"
        case gameId = "gameId"
        case serverId = "serverId"
        case platform = "platform"
        case sdkVersion = "sdkVersion"
        case appVersion = "appVersion"
    }
}

struct LogoutRequestBody: Encodable {
    let deviceId: String
    let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case deviceId, refreshToken
    }
}

