//
//  DefaultForgetPasswordManager.swift
//  AuthSDK
//
//  Created by X on 4/20/25.
//

import Foundation
import Combine

final class DefaultForgetPasswordManager: ForgetPasswordManager, DeviceIdentifiable, SDKInfo, ForgotPasswordAnalytics {
    
    private var authAPIClient: AuthAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var sessionManager: SessionManager
    private var signature: Signature
    
    public var deviceSecretKey: String {
        return Environment.deviceSecretKey
    }
    
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
    
    func forgetPassword(phoneNumber: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<DatalessServerResponse, any Error> {
        guard let verifiedToken = otpVerifiedToken else {
            BaseAnalytics.track(event: self.eventName, properties: [self.failure:AuthErrorResponse.otpError().message])
            return Fail(error: AuthErrorResponse.otpError()).eraseToAnyPublisher()
        }
        
        guard let gameId = self.gameInfoStorage.gameID, let appVersion = gameInfoStorage.appVersion else {
            BaseAnalytics.track(event: self.eventName, properties: [self.failure:AuthErrorResponse.sdkNotInitialized().message])
            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
        }
        
        let _ = Int(Date().timeIntervalSince1970)
        
//        guard let signature = try? self.signature.sign(timestampInSeconds: timeStamp) else {
//            return Fail(error: AuthErrorResponse.sdkNotInitialized()).eraseToAnyPublisher()
//        }
        let body = ForgotPasswordRequestBody(
            appVersion: appVersion,
//            timestamp: timeStamp,
            deviceId: deviceID,
            gameId: gameId,
            phone: phoneNumber,
            password: password,
            platform: platform,
            otpVerifiedToken: verifiedToken,
            sdkVersion: versionName
        )
        BaseAnalytics.track(event: self.eventName, properties: [self.request : body.toDictionary().toMixpanelType()])
        
        return authAPIClient.forgetPassword(header: nil, body: body.toDictionary().toMixpanelType())
            .map { sessionDTO in
//                self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                let model = sessionDTO.toModel()
//                try? self.sessionManager.saveSession(authSession: model)
                return model.toResponse()
            }
            .eraseToAnyPublisher()
    }
    
    func requestOTP(phone: String) -> AnyPublisher<OTPSendableResponse, any Error> {
        
        let otpSendableParameters: OTPSendableParameters = OTPSendableParameters(phone: phone)
        
        do {
            try otpSendableParameters.validate()
        }
        catch {
            BaseAnalytics.track(event: self.requestOTP, properties: [self.failure:AuthErrorResponse.matchError().message])
            return Fail(error: AuthErrorResponse.matchError()).eraseToAnyPublisher()
        }
        var timeStamp: Int = 0
        var sign: String = ""
        do {
            timeStamp = Int(Date().timeIntervalSince1970)
            sign = try signature.sign(phone: phone, type: OTPType.forgotPassword.rawValue, timestampInSeconds: timeStamp)
        } catch {
            BaseAnalytics.track(event: self.requestOTP, properties: [self.failure:AuthErrorResponse.sdkSignatureError().message])
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
        }
        
        do {
            let body = OTPSendableBody(
                phone: otpSendableParameters.phone,
                deviceId: deviceID,
                mode: OTPMode.sms,
                type: OTPType.forgotPassword,
                timestamp: timeStamp,
                sign: sign
            )
            BaseAnalytics.track(event: self.requestOTP, properties: [self.request:body.toDictionary().toMixpanelType()])
            return authAPIClient.requestOTP(header: nil, body: body.toDictionary())
                .map { resDTO in
                    return resDTO.data.toModel().toResponse()
                }
                .eraseToAnyPublisher()
        } catch {
            BaseAnalytics.track(event: self.requestOTP, properties: [self.failure: error.localizedDescription])
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    func verifyOTP(phone: String, code: String) -> AnyPublisher<OTPVerifiableResponse, any Error> {
//        guard let phone = gamePlayerStorage.phone else {
//            return Fail(error: AuthErrorResponse.otpError()).eraseToAnyPublisher()
//        }
        
        let otpVerifiableParameters: OTPVerifiableParameters = OTPVerifiableParameters(phone: phone, code: code)
        
        do {
            try otpVerifiableParameters.validate()
        } catch {
            BaseAnalytics.track(event: self.verifyOTP, properties: [self.failure: AuthErrorResponse.otpError().message])
            return Fail(error: AuthErrorResponse.otpError()).eraseToAnyPublisher()
        }
        
        var timeStamp: Int = 0
        var sign: String = ""
        do {
            timeStamp = Int(Date().timeIntervalSince1970)
            sign = try signature.sign(phone: phone, type: OTPType.forgotPassword.rawValue, timestampInSeconds: timeStamp)
        } catch {
            BaseAnalytics.track(event: self.verifyOTP, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
        }
        
        do {
            let body = OTPVerifiableBody(
                phone: phone,
                deviceId: deviceID,
                mode: OTPMode.sms,
                type: OTPType.forgotPassword,
                timestamp: timeStamp,
                otp: code,
                sign: sign
            )
            
            BaseAnalytics.track(event: self.verifyOTP, properties: [self.request: body.toDictionary().toMixpanelType()])
            
            return authAPIClient.verifyOTP(header: nil, body: body.toDictionary())
                .tryMap { resDTO in
                    
                    guard let token = resDTO.data.otpVerifiedToken else {
                        return resDTO.data.toModel().toFailureResponse()
                    }
                    try SensitiveDataManager.shared.set(token, for: .otpVerifiedToken)
                    return resDTO.data.toModel().toSuccessResponse()
                }
                .eraseToAnyPublisher()
        } catch {
            BaseAnalytics.track(event: self.verifyOTP, properties: [self.failure: error.localizedDescription])
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

private struct ForgotPasswordRequestBody: Encodable {
    let appVersion: String
    let deviceId: String
    let gameId: Int
    let type: String = "phone"
    let phone: String
    let password: String
    let platform: String
    let otpVerifiedToken: String
    let sdkVersion: String
}

