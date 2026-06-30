//
//  DefaultRefreshTokenManager.swift
//  AuthSDK
//

import Foundation
import Combine

final class DefaultRefreshTokenManager: RefreshTokenManager, DeviceIdentifiable, SDKInfo, RefreshTokenAnalytics {
    
    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var sessionManager: SessionManager
    private var signature: Signature
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    init(authAPIClient: AuthAPIClient,
         gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage(),
         sessionManager: SessionManager = KeyChainSessionManager(),
         signature: Signature = SHA256Signature()
         
    ) {
        self.authAPIClient = authAPIClient
        self.gameInfoStorage = gameInfoStorage
        self.sessionManager = sessionManager
        self.signature = signature
    }
    
    func refreshToken() -> AnyPublisher<AuthSessionResponse, any Error> {
        guard let packageName = self.gameInfoStorage.packageName else {
            BaseAnalytics.track(event: self.eventName, properties: [self.failure: AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
        }
        
        guard let appVersion = gameInfoStorage.appVersion else {
            BaseAnalytics.track(event: self.eventName, properties: [self.failure: AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
        }
        
        guard let gameId = self.gameInfoStorage.gameID else {
            BaseAnalytics.track(event: self.eventName, properties: [self.failure: AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
        }
        
        guard let refreshToken = try? self.sessionManager.getSession()?.refreshToken else {
            BaseAnalytics.track(event: self.eventName, properties: [self.failure: AuthErrorResponse.unauthenticated().message])
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
        
        guard let sign = try? signature.sign(refreshToken: refreshToken) else {
            BaseAnalytics.track(event: self.eventName, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
        }
     
        let body = RefreshTokenRequestBody(
            packageName: packageName,
            deviceId: deviceID,
            platform: platform,
            sdkVersion: versionName,
            appVersion: appVersion,
            gameId: gameId,
            refreshToken: refreshToken,
            sign: sign
        )
        BaseAnalytics.track(event: self.eventName, properties: [self.request: body.toDictionary().toMixpanelType()])
        
        return authAPIClient.refreshToken(body: body.toDictionary())
            .tryMap { authSessionResDTO in
                let model = authSessionResDTO.data.toModel()
                
                try? self.sessionManager.saveSession(authSession: model, isRefreshToken: true)
                
                return model.toResponse()
            }
            .eraseToAnyPublisher()
    }
}

struct RefreshTokenRequestBody: Encodable {
    let packageName: String
    let deviceId: String
    let platform: String
    let sdkVersion: String
    let appVersion: String
    let gameId: Int
    let refreshToken: String
    let sign: String
    
    private enum CodingKeys: String, CodingKey {
        case packageName = "packageName"
        case deviceId = "deviceId"
        case platform = "platform"
        case sdkVersion = "sdkVersion"
        case appVersion = "appVersion"
        case gameId = "gameId"
        case refreshToken = "refreshToken"
        case sign = "sign"
    }
}

