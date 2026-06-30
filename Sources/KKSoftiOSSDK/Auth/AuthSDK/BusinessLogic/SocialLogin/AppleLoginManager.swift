//
//  AppleLoginManager.swift
//  AuthSDK
//
//  Created by X on 6/2/25.
//

import Foundation
import Combine
import AuthenticationServices

final class AppleLoginManager: NSObject,
                                      SocialLoginManager,
                                      DeviceIdentifiable,
                                      SDKInfo,
                                      LoginAnalytics,
                                      ASAuthorizationControllerDelegate,
                                      ASAuthorizationControllerPresentationContextProviding
{
    
    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var gamePlayerStorage: GamePlayerStorage
    private var sessionManager: SessionManager
    private var signature: Signature
    private var cancellables = Set<AnyCancellable>()
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    /// Subject that emits exactly one identityToken (String) or a failure.
    private var tokenSubject = PassthroughSubject<String, Error>()

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
        super.init()
    }
    
    func login() -> AnyPublisher<AuthSessionResponse, any Error> {
        let tokenSubject = PassthroughSubject<String, Error>()
        self.tokenSubject = tokenSubject

        // 1) Wire up Apple callbacks — when Apple returns,
        //    our ASAuthorizationControllerDelegate methods will feed into `tokenSubject`.
        AppleSignInController.shared.delegate = self

        // 2) Kick off the Apple flow (this will present Apple’s sign-in UI).
        DispatchQueue.main.async {
            AppleSignInController.shared.startSignInWithAppleFlow()
        }

        // 3) Wait for exactly one identityToken, then flatMap to your backend call.
        return tokenSubject
            .first() // Take only a single token (or a single failure)
            .flatMap { [weak self] token -> AnyPublisher<AuthSessionResponse, Error> in
                guard let self = self else {
                    // If `self` has deallocated, we can’t proceed.
                    return Fail<AuthSessionResponse, Error>(
                        error: AuthErrorResponse.unauthenticated() as Error
                    )
                    .eraseToAnyPublisher()
                }

                // 4a) Unwrap & validate each required value directly from `self`
                guard let deviceId: String? = self.deviceID
                else {
                    BaseAnalytics.track(
                        event: self.appleLogin,
                        properties: [ self.failure: AuthErrorResponse.sdkNotInitialized().message ]
                    )
                    return Fail<AuthSessionResponse, Error>(
                        error: AuthErrorResponse.sdkNotInitialized() as Error
                    )
                    .eraseToAnyPublisher()
                }

                guard let platform: String? = self.platform
                else {
                    BaseAnalytics.track(
                        event: self.appleLogin,
                        properties: [ self.failure: AuthErrorResponse.sdkNotInitialized().message ]
                    )
                    return Fail<AuthSessionResponse, Error>(
                        error: AuthErrorResponse.sdkNotInitialized() as Error
                    )
                    .eraseToAnyPublisher()
                }

                guard let appVersion = self.gameInfoStorage.appVersion,
                      !appVersion.isEmpty
                else {
                    BaseAnalytics.track(
                        event: self.appleLogin,
                        properties: [ self.failure: AuthErrorResponse.sdkNotInitialized().message ]
                    )
                    return Fail<AuthSessionResponse, Error>(
                        error: AuthErrorResponse.sdkNotInitialized() as Error
                    )
                    .eraseToAnyPublisher()
                }

                guard let sdkVersion : String? = self.versionName
                else {
                    BaseAnalytics.track(
                        event: self.appleLogin,
                        properties: [ self.failure: AuthErrorResponse.sdkNotInitialized().message ]
                    )
                    return Fail<AuthSessionResponse, Error>(
                        error: AuthErrorResponse.sdkNotInitialized() as Error
                    )
                    .eraseToAnyPublisher()
                }

                guard let gameId = self.gameInfoStorage.gameID
                else {
                    BaseAnalytics.track(
                        event: self.appleLogin,
                        properties: [ self.failure: AuthErrorResponse.appNotConfiguredGame().message ]
                    )
                    return Fail<AuthSessionResponse, Error>(
                        error: AuthErrorResponse.appNotConfiguredGame() as Error
                    )
                    .eraseToAnyPublisher()
                }
                
                let serverId = self.gameInfoStorage.serverID

                // 4b) Compute the `sign` string using your existing Signature API
                let sign: String
                do {
                    sign = try self.signature.sign(type: "apple", token: token)
                } catch {
                    BaseAnalytics.track(
                        event: self.appleLogin,
                        properties: [ self.failure: AuthErrorResponse.sdkSignatureError().message ]
                    )
                    return Fail<AuthSessionResponse, Error>(
                        error: AuthErrorResponse.sdkSignatureError() as Error
                    )
                    .eraseToAnyPublisher()
                }

                // 5) Build your request body
                let requestBody = AppleLoginRequestBody(
                    oauthToken: token,
                    deviceId:   deviceId ?? "",
                    gameId:     gameId,
                    serverId:   serverId,
                    platform:   platform ?? "",
                    sdkVersion: sdkVersion ?? "1.0.0",
                    appVersion: appVersion,
                    sign:       sign
                )

                // 6) Track the outgoing payload (for analytics)
                BaseAnalytics.track(
                    event: self.appleLogin,
                    properties: [ self.request: requestBody.toDictionary().toMixpanelType() ]
                )

                // 7) Finally, call your backend. We must return a publisher whose Failure = Error,
                //    so we wrap the DTO→Model transformations in a `tryMap` and ensure we end up
                //    with AnyPublisher<AuthSessionResponse, Error>.

                return self.authAPIClient
                    .login(header: nil, body: requestBody.toDictionary())
                    .tryMap { sessionDTO -> AuthSessionResponse in
                        // Convert DTO → Model → save session → to Response
                        let model = sessionDTO.data.toModel()
                        self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID

                        // Persist session, phone number, guest‐flag:
                        try self.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                        try? self.gamePlayerStorage.savePhoneNumber("")
                        try? self.gamePlayerStorage.saveIsGuestUser(false)

                        return model.toResponse()
                    }
                    .mapError { $0 as Error }
                    .flatMap { sessionResponse -> AnyPublisher<AuthSessionResponse, Error> in
                        guard let serverId else {
                            return Just(sessionResponse)
                                .setFailureType(to: Error.self)
                                .eraseToAnyPublisher()
                        }
                        return self.authAPIClient
                            .getCharacter(header: [:], gameId: gameId, serverId: serverId)
                            .map { gameUidResponse in
                                if let characterId = gameUidResponse.data.characterId {
                                    self.gameInfoStorage.characterId = characterId
                                }
                                return sessionResponse
                            }
                            .eraseToAnyPublisher()
                    }
                    .handleEvents(
                        receiveOutput: { response in
                            BaseAnalytics.track(
                                event: self.appleLogin,
                                properties: [ self.success: "\(response)" ]
                            )
                        },
                        receiveCompletion: { completion in
                            if case .failure(let err) = completion {
                                BaseAnalytics.track(
                                    event: self.appleLogin,
                                    properties: [ self.failure: err.localizedDescription ]
                                )
                            }
                        }
                    )
                    .eraseToAnyPublisher()
            }
            // 8) The outer method signature is AnyPublisher<AuthSessionResponse, any Error>
            //    so we need one more upcast to `any Error` if necessary:
            .mapError { $0 as? AuthErrorResponse ?? $0 as Error }              // still Failure = Error
            .eraseToAnyPublisher()                // finally: AnyPublisher<AuthSessionResponse, any Error>
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
            guard let gameId = self.gameInfoStorage.gameID else {
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
    
    func getPhoneNumber() throws -> String? {
        try gamePlayerStorage.getPhoneNumber()
    }
    
    func getServerId() -> Int? {
        gameInfoStorage.serverID
    }
    
    func getGameId() -> Int? {
        gameInfoStorage.gameID
    }
    
    func logout() -> AnyPublisher<DatalessServerResponse, any Error> {
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
    
    // ------------------------------------------------------------------------
    // MARK: - ASAuthorizationController Delegate / Presentation
    
    /// Called by `AppleSignInController` when Apple returns a valid credential.
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = appleIDCredential.identityToken,
            let tokenString = String(data: tokenData, encoding: .utf8)
        else {
            tokenSubject.send(completion: .failure(AppleSignInError.missingToken))
            return
        }
        tokenSubject.send(tokenString)
        tokenSubject.send(completion: .finished)
    }
    
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        tokenSubject.send(completion: .failure(error))
    }
    
    /// Provide a window for presenting the Apple ID sheet.
    public func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        UIApplication.shared.authSDKKeyWindow ?? ASPresentationAnchor()
    }
}

// ------------------------------------------------------------------------
// MARK: - AppleSignInController (Singleton Wrapper for ASAuthorizationController)

/// We wrap ASAuthorizationController into a reusable singleton so that
/// we can assign `self` as delegate/presentation context and call `performRequests()`.
final class AppleSignInController: NSObject {
    static let shared = AppleSignInController()
    
    /// Delegate will be your `DefaultAppleLoginManager`
    weak var delegate: (ASAuthorizationControllerDelegate & ASAuthorizationControllerPresentationContextProviding)?
    
    private override init() {
        super.init()
    }
    
    func startSignInWithAppleFlow() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }
}

fileprivate struct AppleLoginRequestBody: Encodable {
    let provider: String = "apple"
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

// ------------------------------------------------------------------------
// MARK: - Helper: AppleSignInError

public enum AppleSignInError: LocalizedError {
    case missingToken
    public var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Unable to retrieve identity token from Apple."
        }
    }
}
