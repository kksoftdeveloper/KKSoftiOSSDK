//
//  SocialLoginManager.swift
//  AuthSDK
//

import Foundation
import Combine
import GoogleSignIn

final class GoogleLoginManager: SocialLoginManager, DeviceIdentifiable, SDKInfo, LoginAnalytics {
    
    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var gamePlayerStorage: GamePlayerStorage
    private var sessionManager: SessionManager
    private var signature: Signature
    private var cancellables = Set<AnyCancellable>()
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
        self.gameInfoStorage = gameInfoStorage
        self.gamePlayerStorage = gamePlayerStorage
    }

    func login() -> AnyPublisher<AuthSessionResponse, Error> {
        
        return Future<AuthSessionResponse, Error> { [weak self] promise  in
            do {
                let _: GoogleLoginParameters = try GoogleLoginParameters.fromSensitiveData()
                
                guard let deviceId = self?.deviceID, !deviceId.isEmpty else {
                    BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let platform = self?.platform, !platform.isEmpty else {
                    BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let appVersion = self?.gameInfoStorage.appVersion, !appVersion.isEmpty else {
                    BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let sdkVersion = self?.versionName, !sdkVersion.isEmpty else {
                    BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let gameId = self?.gameInfoStorage.gameID else {
                    BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.appNotConfiguredGame().message])
                    promise(.failure(AuthErrorResponse.appNotConfiguredGame()))
                    return
                }
                
                guard let presentingVC = UIApplication.shared.authSDKTopViewController else {
                    BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.googleUnknownError().message])
                    promise(.failure(AuthErrorResponse.googleUnknownError()))
                    return
                }
                
                GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
                    if let error = error {
                        BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": error.localizedDescription])
                        promise(.failure(error))
                        return
                    }
                    
                    
                    guard let result = result else {
                        BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.googleUnknownError().message])
                        promise(.failure(AuthErrorResponse.googleUnknownError()))
                        return
                    }
                    
                    guard let oauthToken = result.user.idToken?.tokenString else {
                        BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.googleAuthenticateError().message])
                        promise(.failure(AuthErrorResponse.googleAuthenticateError()))
                        return
                    }
                    
                    guard let sign = try? self?.signature.sign(type: "google", token: oauthToken) else {
                        BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.sdkSignatureError().message])
                        promise(.failure(AuthErrorResponse.sdkSignatureError()))
                        return
                    }
                    
                    let serverId = self?.gameInfoStorage.serverID
                    
                    let body = GoogleLoginRequestBody(
                        oauthToken: oauthToken,
                        deviceId: deviceId,
                        gameId: gameId,
                        serverId: serverId,
                        platform: platform,
                        sdkVersion: sdkVersion,
                        appVersion: appVersion,
                        sign: sign
                    )
                    BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.request ?? "request": body.toDictionary().toMixpanelType()])
                    
                    self?.authAPIClient.login( header: nil, body: body.toDictionary())
                        .map { sessionDTO in
                            let model = sessionDTO.data.toModel()
                            self?.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                            try? self?.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                            try? self?.gamePlayerStorage.savePhoneNumber("")
                            try? self?.gamePlayerStorage.saveIsGuestUser(false)
                            return model.toResponse()
                        }
                        .flatMap { sessionResponse -> AnyPublisher<AuthSessionResponse, Error> in
                            guard let strongSelf = self, let serverId else {
                                return Just(sessionResponse)
                                    .setFailureType(to: Error.self)
                                    .eraseToAnyPublisher()
                            }
                            return strongSelf.authAPIClient
                                .getCharacter(header: [:], gameId: gameId, serverId: serverId)
                                .map { gameUidResponse in
                                    if let characterId = gameUidResponse.data.characterId {
                                        strongSelf.gameInfoStorage.characterId = characterId
                                    }
                                    return sessionResponse
                                }
                                .eraseToAnyPublisher()
                        }
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": error.localizedDescription])
                                promise(.failure(error as? AuthErrorResponse ?? AuthErrorModel.googleReceiveResultError()))
                            }
                        }, receiveValue: { response in
                            promise(.success(response))
                        })
                        .store(in: &self!.cancellables)
                }
            } catch {
                BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": error.localizedDescription])
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func updateInfo(_ data: AccountInformation) -> AnyPublisher<Bool, any Error> {
        guard let sign = try? signature.updateIfo(data) else {
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
        }
        let body = AccountInformation(avatarUrl: data.avatarUrl, displayName: data.displayName, personalInfo: data.personalInfo, guardianInfo: data.guardianInfo, sign: sign
            
        )
        return authAPIClient.updateInfo(header: nil, body: body.toDictionary())
            .map { isSuccess in
                return isSuccess
            }
            .eraseToAnyPublisher()
    }
    
    /*
    func getAuthSesssion() -> AnyPublisher<AuthSessionResponse, Error> {
        do {
            debugPrint("GetAuthSession-GoogleManager")
            guard let authSessionResponse = try sessionManager.getSession()?.toResponse() else {
                BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
                let notificationCenter = NotificationCenter.default
                notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
                //                return Fail(error: AuthErrorResponse.unauthenticated())
                //                    .eraseToAnyPublisher()
                throw AuthErrorResponse.unauthenticated()
            }
            guard let gameId = self.gameInfoStorage.gameID else {
                //                return Fail(error: AuthErrorResponse.appNotConfiguredGame())
                //                    .eraseToAnyPublisher()
                throw AuthErrorResponse.appNotConfiguredGame()
            }
            
            guard let serverId = self.gameInfoStorage.serverID else {
                //                return Fail(error: AuthErrorResponse.appNotConfiguredGameServer())
                //                    .eraseToAnyPublisher()
                throw AuthErrorResponse.appNotConfiguredGameServer()
            }
            
            let header = ["Authorization": "Bearer \(authSessionResponse.accessToken)"]
            
            return authAPIClient
                .getCharacter(header: header, gameId: gameId, serverId: serverId)
                .flatMap { gameUidResponse in
                    if let gameUUID = gameUidResponse.data.gameUUID, gameUUID == self.gameInfoStorage.gameUUID {
                        BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.success: "Get Auth Session Successfully"])
                        return Just(authSessionResponse.copy(gameUUID: gameUUID))
                            .handleEvents(receiveOutput: { session in
                                AuthTracking.handleRetentionD1IfNeeded(session: session)
                            })
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    } else {
                        debugPrint("GetAuthSession-GoogleManager with gameUUID mismatch")
                        BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
                        return Fail(error: AuthErrorResponse.unauthenticated())
                            .eraseToAnyPublisher()
                    }
                }
//                .mapError { error -> Error in
//                    if let authError = error as? AuthErrorResponse {
//                        debugPrint("❌ GetAuthSession: \(authError.code) - \(authError.message)")
//                        return authError
//                    } else {
//                        debugPrint("❌ GetAuthSession Unknown error: \(error.localizedDescription)")
//                        return error
//                    }
//                }
                .eraseToAnyPublisher()
        } catch {
            debugPrint("GetAuthSession-GoogleManager with something wrong")
            BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
            return Fail(error: AuthErrorResponse.unauthenticated())
                .eraseToAnyPublisher()
        }
    }
     */
    
    func getLocalAuthSesssion() -> AnyPublisher<AuthSessionResponse, any Error> {
        do {
            guard let authSessionResponse = try sessionManager.getSession()?.toResponse() else {
                BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
                let notificationCenter = NotificationCenter.default
                notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
//                return Fail(error: AuthErrorResponse.unauthenticated())
//                    .eraseToAnyPublisher()
                //                return Fail(error: AuthErrorResponse.unauthenticated())
                //                    .eraseToAnyPublisher()
                throw AuthErrorResponse.unauthenticated()
            }
            guard let _ = self.gameInfoStorage.gameID else {
                //                return Fail(error: AuthErrorResponse.appNotConfiguredGame())
                //                    .eraseToAnyPublisher()
                throw AuthErrorResponse.appNotConfiguredGame()
            }
            let refreshed = authSessionResponse.copy(
                gameUUID: self.gameInfoStorage.gameUUID
            )
            BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.success: "gameUUID: \(String(describing: gameInfoStorage.gameUUID))"])
            
            return Just(refreshed)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        } catch {
            debugPrint("GetAuthSession: early throw -> \(error)")
            BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
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
            GIDSignIn.sharedInstance.signOut()

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
}

fileprivate struct GoogleLoginRequestBody: Encodable {
    let provider: String = "google"
    let oauthToken: String
    let deviceId: String
    let gameId: Int
    let serverId: Int?
    let platform: String
    let sdkVersion: String
    let appVersion: String
    let sign: String
    
    private enum CodingKeys: String, CodingKey {
        case provider = "type"
        case oauthToken = "token"
        case deviceId = "deviceId"
        case gameId = "gameId"
        case serverId = "serverId"
        case platform = "platform"
        case sdkVersion = "sdkVersion"
        case appVersion = "appVersion"
        case sign = "sign"
    }
}
