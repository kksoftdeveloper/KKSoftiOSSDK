//
//  FacebookLoginManager.swift
//  AuthSDK
//

import Foundation
import Combine
import FBSDKCoreKit
import UIKit
import FBSDKLoginKit


final class FacebookLoginManager: SocialLoginManager, DeviceIdentifiable, SDKInfo, LoginAnalytics {
    
    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var gamePlayerStorage: GamePlayerStorage
    private var sessionManager: SessionManager
    private var signature: Signature
    
    private var cancellables = Set<AnyCancellable>()
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    private lazy var fbLoginManager: LoginManager = LoginManager()
    
    private var isLoggedIn: Bool = false
    
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

    func login() -> AnyPublisher<AuthSessionResponse, Error>  {
        return Future<AuthSessionResponse, Error> { [weak self] promise in
            do {
                
                let _: FacebookLoginParameters = try FacebookLoginParameters.fromSensitiveData()
                guard let deviceId = self?.deviceID, !deviceId.isEmpty else {
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let platform = self?.platform, !platform.isEmpty else {
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let appVersion = self?.gameInfoStorage.appVersion, !appVersion.isEmpty else {
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let sdkVersion = self?.versionName, !sdkVersion.isEmpty else {
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let gameId = self?.gameInfoStorage.gameID else {
                    promise(.failure(AuthErrorResponse.appNotConfiguredGame()))
                    return
                }
                
                let serverID = self?.gameInfoStorage.serverID
                
                self?.requestLogin { [weak self] result in
                    guard let self = self else {
                        promise(.failure(AuthErrorResponse.facebookAuthenticateError()))
                        return
                    }
                    switch result {
                    case .success(let token):
                        
                        guard let sign = try? self.signature.sign(type: "facebook", token: token) else {
                            BaseAnalytics.track(event: self.facebookLogin, properties: [self.failure : AuthErrorResponse.sdkSignatureError().message])
                            promise(.failure(AuthErrorResponse.sdkSignatureError()))
                            return
                        }
                        
                        let body: FacebookLoginRequestBody = FacebookLoginRequestBody(
                            oauthToken: token,
                            deviceId: deviceId,
                            gameId: gameId,
                            serverId: serverID,
                            platform: platform,
                            sdkVersion: sdkVersion,
                            appVersion: appVersion,
                            sign: sign
                        )
                        
                        authAPIClient.login(header: nil, body: body.toDictionary())
                            .map { sessionDTO in
                                let model = sessionDTO.data.toModel()
                                self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                                try? self.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                                try? self.gamePlayerStorage.savePhoneNumber("")
                                try? self.gamePlayerStorage.saveIsGuestUser(false)
                                return model.toResponse()
                            }
                            .flatMap { sessionResponse -> AnyPublisher<AuthSessionResponse, Error> in
                                guard let serverID else {
                                    return Just(sessionResponse)
                                        .setFailureType(to: Error.self)
                                        .eraseToAnyPublisher()
                                }
                                return self.authAPIClient
                                    .getCharacter(header: [:], gameId: gameId, serverId: serverID)
                                    .map { gameUidResponse in
                                        if let characterId = gameUidResponse.data.characterId {
                                            self.gameInfoStorage.characterId = characterId
                                        }
                                        return sessionResponse
                                    }
                                    .eraseToAnyPublisher()
                            }
                            .sink(receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    promise(.failure(error))
                                }
                            }, receiveValue: { [weak self] response in
                                self?.isLoggedIn = true
                                promise(.success(response))
                            })
                            .store(in: &cancellables)
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            } catch {
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
            print("GetAuthSession: early throw -> \(error)")
            BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
    }
    
    func getAuthSesssion() -> AnyPublisher<AuthSessionResponse, Error> {
        do {
            print("GetAuthSession: entering")
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
                    receiveSubscription: { _ in print("GetAuthSession: getCharacter subscribed") },
                    receiveOutput: { resp in print("GetAuthSession: getCharacter value -> \(resp)") },
                    receiveCompletion: { print("GetAuthSession: getCharacter completion = \($0)") },
                    receiveCancel: { print("GetAuthSession: getCharacter cancelled") }
                )
                .flatMap { gameUidResponse in
                    print("GetAuthSession: gameUidResponse -> \(gameUidResponse)")
                    print("GetAuthSession: gameInfoStorage -> \(String(describing: self.gameInfoStorage.gameUUID))")
                    print("GetAuthSession: gameInfoStorage -> \(String(describing: gameUidResponse.data.characterId))")
                    if let characterId = gameUidResponse.data.characterId {
                        print("GetAuthSession: success, returning session with characterId \(characterId)")
                        self.gameInfoStorage.characterId = characterId
                    }
                    if let gameUUID = gameUidResponse.data.gameUUID, self.gameInfoStorage.gameUUID?.contains(gameUUID) == true {
                        BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.success: "Get Auth Session Successfully"])
                        print("GetAuthSession: success, returning session with gameUUID \(gameUUID)")
                        return Just(authSessionResponse.copy(gameUUID: gameUUID))
                            .handleEvents(receiveOutput: { session in
                                AuthTracking.handleRetentionD1IfNeeded(session: session)
                            })
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    } else {
                        let err = AuthErrorResponse.unauthenticated()
                        BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: err.message])
                        print("GetAuthSession: gameUUID mismatch or nil -> failing unauthenticated")
                        return Fail(error: err).eraseToAnyPublisher()
                    }
                }
                .handleEvents(
                    receiveSubscription: { _ in print("GetAuthSession: flatten subscribed") },
                    receiveOutput: { _ in print("GetAuthSession: output session") },
                    receiveCompletion: { print("GetAuthSession: completion = \($0)") },
                    receiveCancel: { print("GetAuthSession: cancelled") }
                )
                .eraseToAnyPublisher()

        } catch {
            print("GetAuthSession: early throw -> \(error)")
            BaseAnalytics.track(event: self.getLatestAuthSession, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
    }

    func logout() -> AnyPublisher<DatalessServerResponse, Error> {
        do {
            fbLoginManager.logOut()

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

    func isAuthenticated() -> Bool {
        isLoggedIn
    }
    
    
    func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }

    private func requestLogin(_ completion: @escaping (Result<String, Error>) -> Void) {
        // Ensure the configuration object is valid
        guard let configuration = LoginConfiguration(
            permissions:["email", "public_profile"],
            tracking: .limited,
            nonce: UUID().uuidString
        )
        else {
            completion(.failure(AuthErrorResponse.facebookUnknownError()))
            return
        }
        DispatchQueue.main.async {
            self.fbLoginManager.logOut()
//            if let token = AccessToken.current, token.isExpired == false {
//                self.logInfo(token)
//                completion(.success(token.tokenString))
//                return
//            }
            guard let presentingVC = UIApplication.shared.authSDKTopViewController else {
//                BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.googleUnknownError().message])
                completion(.failure(AuthErrorResponse.facebookUnknownError()))
                return
            }
            self.fbLoginManager.logIn(viewController: presentingVC, configuration: configuration, completion: { result in
                switch result {
                case .cancelled:
                    print("FB Login cancelled")
                    completion(.failure(AuthErrorResponse.socialUserCancels()))
                    break
                
                case .failed:
                    print("FB Login failed")
                    completion(.failure(AuthErrorResponse.facebookUnknownError()))
                    break
                
                case .success:
                    // getting id token string
                    
                    if let tokenString = AuthenticationToken.current?.tokenString {
                        print("FB Login success \(tokenString)")
                        completion(.success(tokenString))
                        
                    } else {
                        print("FB Login unauthenticaed")
                        completion(.failure(AuthErrorResponse.facebookAuthenticateError()))
                    }
                    break
                }
            })
            /*
            self.fbLoginManager.logIn(
                permissions: [FBSDKCoreKit.Permission.publicProfile.name, FBSDKCoreKit.Permission.email.name],
                // tracking: LoginTracking = .enabled,
                from: presentingVC
            ) { [weak self] result, error in
                    if let token = result?.token {
                        self?.logInfo(token)
                        completion(.success(token.tokenString))
                        
                    } else if result?.isCancelled == true {
                        completion(.failure(AuthErrorResponse.socialUserCancels()))
                        
                    } else if let _ = error {
                        completion(.failure(AuthErrorResponse.facebookUnknownError()))
                        
                    } else {
                        completion(.failure(AuthErrorResponse.unknownError()))
                    }
                }
             */
        }
    }
    
    private func logInfo(_ token: AccessToken) {
        print("✅ Login with facebook success!" +
              "\nGranted permission: \(token.permissions)" +
              "\nDeclined permission: \(token.declinedPermissions)" +
              "\nUserID: \(token.userID)" +
              "\nAccess Token: \(token.tokenString)")
    }

//    private func fetchLoggedInProfile() async -> Any? {
//        return await withCheckedContinuation { continuation in
//            GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name"]).start { GraphRequestConnection, result, error in
//                if error == nil, let fbDetails = result as? NSDictionary {
//                    print("✅ Login with facebook info: \(fbDetails)")
//                    continuation.resume(returning: fbDetails)
//                } else {
//                    continuation.resume(returning: error)
//                }
//            }
//        }
//    }
    
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


struct FacebookLoginRequestBody: Encodable {
    let provider: String = "facebook"
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


