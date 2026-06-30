//
//  PhonePasswordLoginManager.swift
//  AuthSDK
//

import Foundation
import Combine

final class PhonePasswordLoginManager: UsernamePasswordLoginManager, DeviceIdentifiable, SDKInfo, LoginAnalytics {
    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var gamePlayerStorage: GamePlayerStorage
    private var sessionManager: SessionManager
    private var signature: Signature
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    init(authAPIClient: AuthAPIClient,
         sessionManager: SessionManager = KeyChainSessionManager(),
         gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage(),
         signature: Signature = SHA256Signature(),
         gamePlayerStorage: GamePlayerStorage = GamePlayerKeychainStorage()
    ) {
        self.authAPIClient = authAPIClient
        self.sessionManager = sessionManager
        self.gameInfoStorage = gameInfoStorage
        self.signature = signature
        self.gamePlayerStorage = gamePlayerStorage
    }

    func login(phoneNumber: String, password: String) -> AnyPublisher<AuthSessionResponse, Error> {
        do {
            let _ = try PhoneLoginParameters(phone: phoneNumber, password: password).validate()
            
            guard let gameId = gameInfoStorage.gameID else {
                BaseAnalytics.track(event: self.phoneLogin, properties: [self.failure: AuthErrorResponse.appNotConfiguredGame().message])
                return Fail(error: AuthErrorResponse.appNotConfiguredGame())
                    .eraseToAnyPublisher()
            }
            
            let serverId = gameInfoStorage.serverID
            
            guard let appVersion = gameInfoStorage.appVersion, !appVersion.isEmpty else {
                BaseAnalytics.track(event: self.phoneLogin, properties: [self.failure: AuthErrorResponse.sdkNotInitialized().message])
                return Fail(error: AuthErrorResponse.sdkNotInitialized())
                    .eraseToAnyPublisher()
            }
            
            guard let sign = try? signature.sign(phone: phoneNumber, type: "phone") else {
                BaseAnalytics.track(event: self.phoneLogin, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
                return Fail(error: AuthErrorResponse.sdkSignatureError())
                    .eraseToAnyPublisher()
            }
            
            let body = PhoneLoginRequestBody(
                appVersion: appVersion,
                sdkVersion: versionName,
                platform: platform,
                phone: phoneNumber,
                password: password,
                gameId: gameId,
                serverId: serverId,
                deviceId: deviceID,
                sign: sign
            )
            BaseAnalytics.track(event: self.phoneLogin, properties: [self.request: body.toDictionary().toMixpanelType()])
            
            return authAPIClient.login(header: nil, body: body.toDictionary())
                .map { sessionDTO in
                    self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                    let model = sessionDTO.data.toModel()
                    try? self.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                    try? self.gamePlayerStorage.savePhoneNumber(phoneNumber)
                    try? self.gamePlayerStorage.saveIsGuestUser(false)
                    return model.toResponse()
                }
                .flatMap { sessionResponse -> AnyPublisher<AuthSessionResponse, Error> in
                    guard let serverId else {
                        return Just(sessionResponse)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    return self.getCharacter(gameId: gameId, serverId: serverId)
                        .map { sessionResponse }
                        .catch { _ in Just(sessionResponse).setFailureType(to: Error.self) }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        } catch {
            BaseAnalytics.track(event: self.phoneLogin, properties: [self.failure: error.localizedDescription])
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
    
    func getCharacter(gameId: Int, serverId: Int) -> AnyPublisher<Void, Error> {
        return authAPIClient
            .getCharacter(header: [:], gameId: gameId, serverId: serverId)
            .map { [weak self] gameUidResponse in
                guard let self = self else { return () }
                if let characterId = gameUidResponse.data.characterId {
                    self.gameInfoStorage.characterId = characterId
                }
                return ()
            }
            .eraseToAnyPublisher()
    }
}

struct PhoneLoginRequestBody: Encodable {
    
    let provider: String = "phone"
    let appVersion: String
    let sdkVersion: String
    let platform: String
    let phone: String
    let password: String
    let gameId: Int
    let serverId: Int?
    let deviceId: String
    let sign: String
    
    private enum CodingKeys: String, CodingKey {
        case provider = "type"
        case phone
        case password
        case deviceId
        case gameId
        case serverId
        case platform
        case sdkVersion
        case sign
        case appVersion
    }
}
