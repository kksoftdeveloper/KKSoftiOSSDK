//
//  PhoneSignupManager.swift
//  AuthSDK
//

import Foundation
import Combine


final class PhoneSignupManager : SignupManager, DeviceIdentifiable, SDKInfo, SignupAnalytics {

    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var gamePlayerStorage: GamePlayerStorage
    private var sessionManager: SessionManager
    private var signature: Signature
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    init(authAPIClient: AuthAPIClient,
         gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage(),
         signature: Signature = SHA256Signature(),
         sessionManager: SessionManager = KeyChainSessionManager(),
         gamePlayerStorage: GamePlayerStorage = GamePlayerKeychainStorage()
    ) {
        self.authAPIClient = authAPIClient
        self.gameInfoStorage = gameInfoStorage
        self.signature = signature
        self.sessionManager = sessionManager
        self.gamePlayerStorage = gamePlayerStorage
    }
    
    func signup(phone: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<AuthSessionResponse, any Error> {
        
        guard let verifiedToken = otpVerifiedToken else {
            BaseAnalytics.track(event: self.phoneSignup, properties: [self.failure: AuthErrorResponse.otpError().message])
            return Fail(error: AuthErrorResponse.otpError()).eraseToAnyPublisher()
        }
        
        guard let gameId = self.gameInfoStorage.gameID, let appVersion = gameInfoStorage.appVersion else {
            BaseAnalytics.track(event: self.phoneSignup, properties: [self.failure: AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
        }
        
        guard let serverId = self.gameInfoStorage.serverID else {
            BaseAnalytics.track(event: self.phoneSignup, properties: [self.failure: AuthErrorResponse.appNotConfiguredGameServer().message])
            return Fail(error: AuthErrorResponse.appNotConfiguredGameServer()).eraseToAnyPublisher()
        }
        
        guard let sign = try? signature.sign(phone: phone, password: password, otpVerifiedToken: verifiedToken) else {
            BaseAnalytics.track(event: self.phoneSignup, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
        }
        
        let body = PhoneSignupRequestBody(
            appVersion: appVersion,
            deviceId: deviceID,
            gameId: gameId,
            serverId: serverId,
            phone: phone,
            password: password,
            platform: platform,
            otpVerifiedToken: verifiedToken,
            sdkVersion: versionName,
            sign: sign
        )
        BaseAnalytics.track(event: self.phoneSignup, properties: [self.request: body.toDictionary().toMixpanelType() ])
        return authAPIClient.phoneSignup(header: nil, body: body.toDictionary())
            .map { sessionDTO in
                self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                let model = sessionDTO.data.toModel()
                try? self.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                try? self.gamePlayerStorage.savePhoneNumber(phone)
                try? self.gamePlayerStorage.saveIsGuestUser(false)
                return model.toResponse()
            }
            .eraseToAnyPublisher()
    }
    
    func updateInfo(_ data: AccountInformation) -> AnyPublisher<Bool, any Error> {
        guard let sign = try? signature.updateIfo(data) else {
            BaseAnalytics.track(event: self.updateAccountInfo, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
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
    
    func linkToNewAccount(phone: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<AuthSessionResponse, any Error> {
        guard let verifiedToken = otpVerifiedToken else {
            BaseAnalytics.track(event: self.linkToPhoneAccount, properties: [self.failure: AuthErrorResponse.otpError().message])
            return Fail(error: AuthErrorResponse.otpError()).eraseToAnyPublisher()
        }
        
        guard let gameId = self.gameInfoStorage.gameID, let appVersion = gameInfoStorage.appVersion else {
            BaseAnalytics.track(event: self.linkToPhoneAccount, properties: [self.failure: AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
        }
        
        guard let serverId = self.gameInfoStorage.serverID else {
            BaseAnalytics.track(event: self.linkToPhoneAccount, properties: [self.failure: AuthErrorResponse.appNotConfiguredGameServer().message])
            return Fail(error: AuthErrorResponse.appNotConfiguredGameServer()).eraseToAnyPublisher()
        }
        
        guard let accessToken = try? sessionManager.getSession()?.accessToken else {
            BaseAnalytics.track(event: self.linkToPhoneAccount, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
        debugPrint("access-token: --- \(accessToken)")
        
//        let header = ["Authorization": "Bearer \(accessToken)"]
        
        guard let sign = try? signature.sign(type: "phone", phone: phone, password: password, otpVerifiedToken: verifiedToken) else {
            BaseAnalytics.track(event: self.linkToPhoneAccount, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
        }
        
        let body = LinkPhoneAccountRequestBody(
            appVersion: appVersion,
            deviceId: deviceID,
            gameId: gameId,
            serverId: serverId,
            phone: phone,
            password: password,
            platform: platform,
            otpVerifiedToken: verifiedToken,
            sdkVersion: versionName,
            sign: sign
        )
        BaseAnalytics.track(event: self.linkToPhoneAccount, properties: [self.request: body.toDictionary().toMixpanelType()])
        return authAPIClient.linkToNewAccount(header: [:], body: body.toDictionary())
            .map { sessionDTO in
                self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                let model = sessionDTO.data.toModel()
                try? self.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                try? self.gamePlayerStorage.savePhoneNumber(phone)
                try? self.gamePlayerStorage.saveIsGuestUser(false)
                return model.toResponse()
            }
            .eraseToAnyPublisher()
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

private struct PhoneSignupRequestBody: Encodable {
    let appVersion: String
    let deviceId: String
    let gameId: Int
    let serverId: Int
    let type: String = "phone"
    let phone: String
    let password: String
    let platform: String
    let otpVerifiedToken: String
    let sdkVersion: String
    let sign: String
}

private struct LinkPhoneAccountRequestBody: Encodable {
    let appVersion: String
    let deviceId: String
    let gameId: Int
    let serverId: Int
    let type: String = "phone"
    let phone: String
    let password: String
    let platform: String
    let otpVerifiedToken: String
    let sdkVersion: String
    let sign: String
}
