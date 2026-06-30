//
//  DefaultAuthManager.swift
//  AuthSDK
//

import Foundation
import Combine

public struct DefaultAuthManager: AuthManager, AnalyticsProperties {
    
    public var appVersion: String
    
    public var osVersion: String
    
    public var deviceSecretKey: String
    
    private var initializer: Initialializer?
    private var googleLoginManager: SocialLoginManager?
    private var facebookLoginManager: SocialLoginManager?
    private var appleLoginManager: SocialLoginManager?
    private var otpAuthManager: OTPAuthManager?
    private var emailPasswordLoginManager: UsernamePasswordLoginManager?
    private var phonePasswordLoginManager: UsernamePasswordLoginManager?
    private var guestLoginManager: GuestLoginManager?
    private var gameServerInfoManager: GameServerInfoManager?
    private var signupManager: SignupManager?
    private var refreshTokenManager: RefreshTokenManager?
    private var forgetPasswordManager: ForgetPasswordManager?
    private var linkAccountManager: SocialAccountLinkingManager?
    private var deactivateManager: DeactivateManager?
    
    private var cancellables: Set<AnyCancellable>
    
    private init(
        builder: Builder,
        cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    ) {
        BaseAnalytics.initialize(token: Environment.mixpanelKey)
        self.appVersion = builder.appVersion
        self.osVersion = builder.osVersion
        self.googleLoginManager = builder.googleLoginManager
        self.facebookLoginManager = builder.facebookLoginManager
        self.appleLoginManager = builder.appleLoginManager
        self.otpAuthManager = builder.otpAuthManager
        self.emailPasswordLoginManager = builder.emailPasswordLoginManager
        self.phonePasswordLoginManager = builder.phonePasswordLoginManager
        self.guestLoginManager = builder.guestLoginManager
        self.signupManager = builder.signupManager
        self.refreshTokenManager = builder.refreshTokenManager
        self.forgetPasswordManager = builder.forgetPasswordManager
        self.linkAccountManager = builder.linkAccountManager
        self.deactivateManager = builder.deactivateManager
        self.initializer = builder.initializer
        self.cancellables = cancellables
        deviceSecretKey = Environment.deviceSecretKey
    }
    
    public class Builder {
        var appVersion: String = ""
        
        var osVersion: String = ""
        
        var initializer: Initialializer?
        var googleLoginManager: SocialLoginManager?
        var facebookLoginManager: SocialLoginManager?
        var appleLoginManager: SocialLoginManager?
        var otpAuthManager: OTPAuthManager?
        var emailPasswordLoginManager: UsernamePasswordLoginManager?
        var phonePasswordLoginManager: UsernamePasswordLoginManager?
        var guestLoginManager: GuestLoginManager?
        var gameServerInfoManager: GameServerInfoManager?
        var refreshTokenManager: RefreshTokenManager?
        var signupManager: SignupManager?
        var forgetPasswordManager: ForgetPasswordManager?
        var linkAccountManager: SocialAccountLinkingManager?
        var deactivateManager: DeactivateManager?
        
        public init() {
            let env = Bundle.main.infoDictionary?["APP_ENV"] as? String ?? "production"
            Environment.current = env.lowercased() == "staging" || env.lowercased() == "stag" ? .staging : .production
        }
        
        public func setAppVersion(_ appVersion: String) -> Builder {
            self.appVersion = appVersion
            return self
        }
        
        public func setOSVersion(_ osVersion: String) -> Builder {
            self.osVersion = osVersion
            return self
        }
        
        public func setGoogleLoginManager(_ googleLoginManager: SocialLoginManager) -> Builder {
            self.googleLoginManager = googleLoginManager
            return self
        }
        
        public func setFacebookLoginManager(_ facebookLoginManager: SocialLoginManager) -> Builder {
            self.facebookLoginManager = facebookLoginManager
            return self
        }

        public func setAppleLoginManager(_ appleLoginManager: SocialLoginManager) -> Builder {
            self.appleLoginManager = appleLoginManager
            return self
        }
        
        public func setOTPAuthManager(_ otpAuthManager: OTPAuthManager) -> Builder {
            self.otpAuthManager = otpAuthManager
            return self
        }
        
        public func setPhonePasswordLoginManager(_ phonePasswordLoginManager: UsernamePasswordLoginManager) -> Builder {
            self.phonePasswordLoginManager = phonePasswordLoginManager
            return self
        }
        
        public func setEmailPasswordLoginManager(_ emailPasswordLoginManager: UsernamePasswordLoginManager) -> Builder {
            self.emailPasswordLoginManager = emailPasswordLoginManager
            return self
        }
        
        public func setGuestLoginManager(_ guestLoginManager: GuestLoginManager) -> Builder {
            self.guestLoginManager = guestLoginManager
            return self
        }
        
        public func setInitializer(_ initializer: Initialializer) -> Builder {
            self.initializer = initializer
            return self
        }

        public func setGameServerInfoManager(_ gameServerInfoManager: GameServerInfoManager) -> Builder {
            self.gameServerInfoManager = gameServerInfoManager
            return self
        }
        
        public func setSignupManager(_ signupManager: SignupManager) -> Builder {
            self.signupManager = signupManager
            return self
        }

        public func setRefreshTokenManager(_ refreshTokenManager: RefreshTokenManager) -> Builder {
            self.refreshTokenManager = refreshTokenManager
            return self
        }
        
        public func setForgetPasswordManager(_ forgetPasswordManager: ForgetPasswordManager) -> Builder {
            self.forgetPasswordManager = forgetPasswordManager
            return self
        }
        
        public func setLinkAccountManager(_ linkAccountManager: SocialAccountLinkingManager) -> Builder {
            self.linkAccountManager = linkAccountManager
            return self
        }
        
        public func setDeactivateManager(_ deactivateManager: DeactivateManager) -> Builder {
            self.deactivateManager = deactivateManager
            return self
        }
        
        public func build() -> DefaultAuthManager {
            
            return DefaultAuthManager(builder: self)
                .setting(\.appVersion, appVersion)
                .setting(\.osVersion, osVersion)
                .setting(\.googleLoginManager, googleLoginManager)
                .setting(\.facebookLoginManager, facebookLoginManager)
                .setting(\.appleLoginManager, appleLoginManager)
                .setting(\.otpAuthManager, otpAuthManager)
                .setting(\.emailPasswordLoginManager, emailPasswordLoginManager)
                .setting(\.phonePasswordLoginManager, phonePasswordLoginManager)
                .setting(\.guestLoginManager, guestLoginManager)
                .setting(\.initializer, initializer)
                .setting(\.gameServerInfoManager, gameServerInfoManager)
                .setting(\.signupManager, signupManager)
                .setting(\.refreshTokenManager, refreshTokenManager)
                .setting(\.forgetPasswordManager, forgetPasswordManager)
                .setting(\.linkAccountManager, linkAccountManager)
                .setting(\.deactivateManager, deactivateManager)
        }
    }
    
    public func initSDK(packageName: String, appVersion: String, serverId: Int) -> AnyPublisher<AuthInitResponse, Error> {
        do {
            if packageName.isEmpty || appVersion.isEmpty {
                return Fail(error: AuthErrorResponse.matchError()).eraseToAnyPublisher()
            }
            
            if serverId < 1 {
                let notificationCenter = NotificationCenter.default
                notificationCenter.post(name: NSNotification.Name(NotificationKeys.SERVER_MAINTENANCE_KEY), object: nil)
                return Fail(error: AuthErrorResponse.appNotConfiguredGameServer()).eraseToAnyPublisher()
            }
            
            guard let initializer = self.initializer else {
                throw AuthErrorResponse.unknownError()
            }
            
            
            return initializer.initSDK(packageName: packageName, appVersion: appVersion, serverId: serverId)
        
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    public func login(email: String, password: String) -> AnyPublisher<AuthSessionResponse, Error> {

        do {
            let validatedEmailLoginParameters = EmailLoginParameters(email: email, password: password)
            try validatedEmailLoginParameters.validate()
            
            guard let manager = self.emailPasswordLoginManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            let method = "email"
            return manager.login(phoneNumber: email, password: password)
                .handleEvents(
                    receiveOutput: { session in
                        AuthTracking.logLoginSuccess(method: method, session: session)
                    },
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            AuthTracking.logLoginFailure(method: method, error: error)
                        }
                    }
                )
                .eraseToAnyPublisher()
            
        } catch {
            AuthTracking.logLoginFailure(method: "email", error: error)
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func login(phoneNumber: String, password: String) -> AnyPublisher<AuthSessionResponse, Error> {
       
        do {
            let validatedPhoneLoginParameters = PhoneLoginParameters(phone: phoneNumber, password: password)
            try validatedPhoneLoginParameters.validate()
            
            guard let manager = self.phonePasswordLoginManager else {
                debugPrint(">>>>>> Error: PhonePasswordLoginManager is nil")
                throw AuthErrorResponse.unknownError()
            }
            
            let method = "phone"
            return manager.login(phoneNumber: phoneNumber, password: password)
                .handleEvents(
                    receiveOutput: { session in
                        AuthTracking.logLoginSuccess(method: method, session: session)
                    },
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            AuthTracking.logLoginFailure(method: method, error: error)
                        }
                    }
                )
                .eraseToAnyPublisher()
            
        } catch {
            debugPrint(">>>>>> Error in catch")
            AuthTracking.logLoginFailure(method: "phone", error: error)
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func signup(phoneNumber: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<AuthSessionResponse, Error> {

        do {
            let validatedPhoneSignupParameters = PhoneSignupParameters(phone: phoneNumber, password: password)
            try validatedPhoneSignupParameters.validate()
            
            guard let manager = self.signupManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.signup(phone: phoneNumber, password: password, otpVerifiedToken: otpVerifiedToken)
                .flatMap { session -> AnyPublisher<AuthSessionResponse, Error> in
                    guard
                        let pwdManager = self.phonePasswordLoginManager,
                        let gameId = pwdManager.getGameId(),
                        let serverId = pwdManager.getServerId()
                    else {
                        return Just(session)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    return (pwdManager as? PhonePasswordLoginManager)?
                        .getCharacter(gameId: gameId, serverId: serverId)
                        .map { _ in session }
                        .catch { _ in Just(session).setFailureType(to: Error.self) }
                        .eraseToAnyPublisher()
                        ?? Just(session).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                .handleEvents(
                    receiveOutput: { session in
                        AuthTracking.logRegisterSuccess(method: "phone", session: session)
                    },
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
//                            AuthTracking.logRegisterFailure(method: method, error: error)
                        }
                    }
                )
                .eraseToAnyPublisher()
            
        } catch {
//            AuthTracking.logRegisterFailure(method: "phone_signup", error: error)
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    
    public func linkToNewAccount(phoneNumber: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<AuthSessionResponse, Error> {

        do {
            let validatedPhoneSignupParameters = PhoneSignupParameters(phone: phoneNumber, password: password)
            try validatedPhoneSignupParameters.validate()
            
            guard let manager = self.signupManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.linkToNewAccount(phone: phoneNumber, password: password, otpVerifiedToken: otpVerifiedToken)
            
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func linkToGoogleAccount() -> AnyPublisher<AuthSessionResponse, any Error> {
        do {
            
            guard let manager = self.linkAccountManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.googleAccountLinker()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    public func linkToFacebookAccount() -> AnyPublisher<AuthSessionResponse, any Error> {
        do {
            
            guard let manager = self.linkAccountManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.facebookAccountLinker()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

//    public func loginWithSocial(provider: String) -> AnyPublisher<AuthSessionResponse, Error> {
//        if provider == "google" {
//            return loginWithGoogle()
//        } else if(provider == "facebook") {
//            return loginWithFacebook()
//        } else {
//            return Fail<AuthSessionResponse, Error>(
//                error: AuthErrorResponse.matchError()
//            )
//            .eraseToAnyPublisher()
//        }
//    }
    
    public func loginWithGoogleAccount() -> AnyPublisher<AuthSessionResponse, Error> {
        do {
            let validatedGoogleLoginParameters = try GoogleLoginParameters.fromSensitiveData()
            try validatedGoogleLoginParameters.validate()
            
            guard let manager = self.googleLoginManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            let method = "google"
            return manager.login()
                .handleEvents(
                    receiveOutput: { session in
                        AuthTracking.logLoginSuccess(method: method, session: session)
                    },
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            AuthTracking.logLoginFailure(method: method, error: error)
                        }
                    }
                )
                .eraseToAnyPublisher()
            
        } catch {
            AuthTracking.logLoginFailure(method: "google", error: error)
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func loginWithFacebookAccount() -> AnyPublisher<AuthSessionResponse, Error> {
        do {
            let validatedFBLoginParameters = try FacebookLoginParameters.fromSensitiveData()
            try validatedFBLoginParameters.validate()
            
            guard let manager = self.facebookLoginManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            let method = "facebook"
            return manager.login()
                .handleEvents(
                    receiveOutput: { session in
                        AuthTracking.logLoginSuccess(method: method, session: session)
                    },
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            AuthTracking.logLoginFailure(method: method, error: error)
                        }
                    }
                )
                .eraseToAnyPublisher()
            
        } catch {
            AuthTracking.logLoginFailure(method: "facebook", error: error)
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func loginWithAppleAccount() -> AnyPublisher<AuthSessionResponse, Error> {
        do {
            guard let manager = self.appleLoginManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            let method = "apple"
            return manager.login()
                .handleEvents(
                    receiveOutput: { session in
                        AuthTracking.logLoginSuccess(method: method, session: session)
                    },
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            AuthTracking.logLoginFailure(method: method, error: error)
                        }
                    }
                )
                .eraseToAnyPublisher()
            
        } catch {
            AuthTracking.logLoginFailure(method: "apple", error: error)
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func loginWithGuest() -> AnyPublisher<AuthSessionResponse, Error> {
        do {
            guard let manager = self.guestLoginManager else {
                throw AuthErrorResponse.unknownError()
            }
            let method = "play-now"
            return manager.login()
                .handleEvents(
                    receiveOutput: { session in
                        AuthTracking.logLoginSuccess(method: method, session: session)
                    },
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            AuthTracking.logLoginFailure(method: method, error: error)
                        }
                    }
                )
                .eraseToAnyPublisher()
        } catch {
            AuthTracking.logLoginFailure(method: "play-now", error: error)
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func getGameInfo() -> AnyPublisher<GameInfoResponse, any Error> {
        do {
            guard let manager = self.gameServerInfoManager else {
                throw AuthErrorResponse.appNotConfigured()
            }
            
            return manager.getGameInfo()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func getGamePublicInfo() -> GamePublicInfoResponse {
        return .init(fanpage: "https://www.facebook.com/profile.php?id=61574162151534", phoneNumber: "+84398686854")
    }
    
    
    public func getGameServerLists() -> AnyPublisher<[GameServerInfoResponse], any Error> {
        do {
            guard let manager = self.gameServerInfoManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.getGameServers()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func updateGameServer(selectedGameServer: GameServerInfoResponse) -> AnyPublisher<String, any Error> {
        do {
            guard let manager = self.gameServerInfoManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.updateGameServer(selectedServerId: selectedGameServer.serverId, selectedServerName: selectedGameServer.serverName)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func requestOTP(phone: String) -> AnyPublisher<OTPSendableResponse, any Error> {
        do {
            guard let manager = self.otpAuthManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.requestOTP(phone: phone)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func verifyOTP(code: String) -> AnyPublisher<OTPVerifiableResponse, any Error> {
        do {
            guard let manager = self.otpAuthManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.verifyOTP(code: code)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func requestOTPForgetPassword(phone: String) -> AnyPublisher<OTPSendableResponse, any Error> {
        do {
            guard let manager = self.forgetPasswordManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.requestOTP(phone: phone)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func verifyOTPForgetPassword(phone: String, code: String) -> AnyPublisher<OTPVerifiableResponse, any Error> {
        do {
            guard let manager = self.forgetPasswordManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.verifyOTP(phone: phone, code: code)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func refreshToken() -> AnyPublisher<AuthSessionResponse, any Error> {
        do {
            guard let manager = self.refreshTokenManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.refreshToken()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func forgetPassword(phoneNumber: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<DatalessServerResponse, any Error> {
        do {
            let validatedPhoneSignupParameters = PhoneSignupParameters(phone: phoneNumber, password: password)
            try validatedPhoneSignupParameters.validate()
            
            guard let manager = self.forgetPasswordManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.forgetPassword(phoneNumber: phoneNumber, password: password, otpVerifiedToken: otpVerifiedToken)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    public func linkGoogleAccount() -> AnyPublisher<AuthSessionResponse, any Error> {
        do {
            
            guard let manager = self.linkAccountManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.googleAccountLinker()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    public func linkFacebookAccount() -> AnyPublisher<AuthSessionResponse, any Error> {
        do {
            
            guard let manager = self.linkAccountManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.facebookAccountLinker()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
//
//    func requestOTP(phoneNumber: String) async throws {
//        try await phoneAuthManager.requestOTP(phone: phoneNumber)
//        let session: AuthSessionModel = try await phoneAuthManager.verifyOTP(phone: phoneNumber, code: "123456")
//    }
//    
//    func verifyOTP(phoneNumber: String, code: String) async throws {
//        try await phoneAuthManager.verifyOTP(phone: phoneNumber, code: "123456")
//    }
//    
//    func refreshToken() async throws {
//        
//    }
//    
    public func logout()  -> AnyPublisher<DatalessServerResponse, Error> {
        if let manager = googleLoginManager {
            return manager.logout()
        }
        if let manager = facebookLoginManager {
            return manager.logout()
        }
        if let manager = appleLoginManager {
            return manager.logout()
        }
        if let manager = otpAuthManager {
            return manager.logout()
        }
        if let manager = emailPasswordLoginManager {
            return manager.logout()
        }
        if let manager = phonePasswordLoginManager {
            return manager.logout()
        }
        if let manager = guestLoginManager {
            return manager.logout()
        }
        
        return Fail(error: AuthErrorResponse.unknownError())
            .eraseToAnyPublisher()
    }
//    
//    func isAuthenticated() -> Bool {
//        false
//    }
    
    public func getAuthSesssion() -> AnyPublisher<AuthSessionResponse, Error> {
        if let manager = googleLoginManager {
            debugPrint("GetAuthSession-Google")
            return manager.getAuthSesssion()
        }
        if let manager = facebookLoginManager {
            debugPrint("GetAuthSession-Facebook")
            return manager.getAuthSesssion()
        }
        if let manager = appleLoginManager {
            debugPrint("GetAuthSession-Apple")
            return manager.getAuthSesssion()
        }
        if let manager = emailPasswordLoginManager {
            debugPrint("GetAuthSession-Email/Password")
            return manager.getAuthSesssion()
        }
        if let manager = phonePasswordLoginManager {
            debugPrint("GetAuthSession-Phone/Password")
            return manager.getAuthSesssion()
        }
        if let manager = guestLoginManager {
            debugPrint("GetAuthSession-Guest/Password")
            return manager.getAuthSesssion()
        }
        return Fail(error: AuthErrorResponse.unknownError())
            .eraseToAnyPublisher()
    }
    
    public func getDeviceID() -> String {
        deviceID
    }
    
    public func getPhoneNumber() -> String {
        if let manager = googleLoginManager {
            return (try? manager.getPhoneNumber()) ?? ""
        }
        if let manager = facebookLoginManager {
            return (try? manager.getPhoneNumber()) ?? ""
        }
        if let manager = appleLoginManager {
            return (try? manager.getPhoneNumber()) ?? ""
        }
        if let manager = emailPasswordLoginManager {
            return (try? manager.getPhoneNumber()) ?? ""
        }
        if let manager = phonePasswordLoginManager {
            return (try? manager.getPhoneNumber()) ?? ""
        }
        if let manager = guestLoginManager {
            return (try? manager.getPhoneNumber()) ?? ""
        }
        return ""
    }
    
    public func getServerId() -> Int? {
        if let manager = googleLoginManager {
            return manager.getServerId()
        }
        if let manager = facebookLoginManager {
            return manager.getServerId()
        }
        if let manager = appleLoginManager {
            return manager.getServerId()
        }
        if let manager = emailPasswordLoginManager {
            return manager.getServerId()
        }
        if let manager = phonePasswordLoginManager {
            return manager.getServerId()
        }
        if let manager = guestLoginManager {
            return manager.getServerId()
        }
        return nil
    }
    
    
    public func getGameId() -> Int? {
        if let manager = googleLoginManager {
            return manager.getGameId()
        }
        if let manager = facebookLoginManager {
            return manager.getGameId()
        }
        if let manager = appleLoginManager {
            return manager.getGameId()
        }
        if let manager = emailPasswordLoginManager {
            return manager.getGameId()
        }
        if let manager = phonePasswordLoginManager {
            return manager.getGameId()
        }
        if let manager = guestLoginManager {
            return manager.getGameId()
        }
        return nil
    }
    
    
    
    public func deactivateAccount() -> AnyPublisher<DatalessServerResponse, any Error> {
        do {
            
            guard let manager = self.deactivateManager else {
                throw AuthErrorResponse.unknownError()
            }
            
            return manager.deactivateAccount()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    public func isGuestUser() -> Bool {
        guestLoginManager?.isGuestUser() ?? false
    }
    
    public func updateAccountInfo(data: AccountInformation) -> AnyPublisher<Bool, any Error> {
        guard let manager = signupManager else {
            return Fail(error: AuthErrorResponse.unknownError()).eraseToAnyPublisher()
        }
        
        return manager.updateInfo(data)
    }
    
    public func updateInfo(_ data: AccountInformation) -> AnyPublisher<Bool, any Error> {
        updateAccountInfo(data: data)
    }
}

// Helper to set private properties after init
private extension DefaultAuthManager {
    func setting<T>(_ keyPath: WritableKeyPath<DefaultAuthManager, T>, _ value: T) -> DefaultAuthManager {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}

public extension DefaultAuthManager {
    static let REFERSH_TOKEN_KEY: String = "KKSOFT.RefreshedToken"
}

@objc public class NotificationKeys: NSObject {
    // Exposes as NSString* to Obj-C
    @objc public static let UNAUTHENTICATED_TOKEN_KEY: String = "KKSOFT.UnauthenticatedToken"
    @objc public static let EXPIRATION_TOKEN_KEY: String = "KKSOFT.ExpirationToken"
    @objc public static let SERVER_MAINTENANCE_KEY: String = "KKSOFT.ServerMaintainance"
    
    @objc public static let IAP_USER_CANCEL: String = "KKSOFT.IAP.UserCancel"
    @objc public static let IAP_INVALID_SKU: String = "KKSOFT.IAP.InvalidSKU"
    @objc public static let IAP_FAIL: String = "KKSOFT.IAP.FAIL"
    @objc public static let IAP_SUCCESS: String = "KKSOFT.IAP.Success"
    @objc public static let IAP_START: String = "KKSOFT.IAP.Start"
}
