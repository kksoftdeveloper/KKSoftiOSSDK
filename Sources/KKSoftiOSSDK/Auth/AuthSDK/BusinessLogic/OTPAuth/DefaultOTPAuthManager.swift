//
//  PhoneAuthManager.swift
//  AuthSDK
//

import Foundation
import Combine

final class DefaultOTPAuthManager: OTPAuthManager, DeviceIdentifiable, SDKInfo, OTPAnalytics {
    
    private var authAPIClient: AuthAPIClient
    private var gamePlayerStorage: GamePlayerStorage
    private var signature: Signature
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    init(authAPIClient: AuthAPIClient,
         gamePlayerStorage: GamePlayerStorage = GamePlayerKeychainStorage(),
         signature: Signature = SHA256Signature()
    ) {
        self.authAPIClient = authAPIClient
        self.gamePlayerStorage = gamePlayerStorage
        self.signature = signature
    }
    
    func requestOTP(phone: String) -> AnyPublisher<OTPSendableResponse, Error> {
        
        let otpSendableParameters: OTPSendableParameters = OTPSendableParameters(phone: phone)
        
        do {
            try otpSendableParameters.validate()
        }
        catch {
            BaseAnalytics.track(event: self.requestOTP, properties: [self.failure: AuthErrorResponse.matchError().message])
            return Fail(error: AuthErrorResponse.matchError()).eraseToAnyPublisher()
        }
        var timeStamp: Int = 0
        var sign: String = ""
        do {
            timeStamp = Int(Date().timeIntervalSince1970)
            sign = try signature.sign(phone: phone, type: OTPType.registration.rawValue, timestampInSeconds: timeStamp)
        } catch {
            BaseAnalytics.track(event: self.requestOTP, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
        }
        
        do {
            let body = OTPSendableBody(
                phone: otpSendableParameters.phone,
                deviceId: deviceID,
                mode: OTPMode.sms,
                type: OTPType.registration,
                timestamp: timeStamp,
                sign: sign
            )
            
            return authAPIClient.requestOTP(header: nil, body: body.toDictionary())
                .map { resDTO in
                    try? self.gamePlayerStorage.savePhoneNumber(otpSendableParameters.phone)
                    BaseAnalytics.track(event: self.requestOTP, properties: [self.success: phone])
                    return resDTO.data.toModel().toResponse()
                }
                .eraseToAnyPublisher()
        } catch {
            BaseAnalytics.track(event: self.requestOTP, properties: [self.failure: error.localizedDescription])
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    func verifyOTP(code: String) -> AnyPublisher<OTPVerifiableResponse , Error> {
        guard let phone = try? gamePlayerStorage.getPhoneNumber() else {
            BaseAnalytics.track(event: self.verifyOTP, properties: [self.failure: AuthErrorResponse.otpError().message])
            return Fail(error: AuthErrorResponse.otpError()).eraseToAnyPublisher()
        }
        
        let otpVerifiableParameters: OTPVerifiableParameters = OTPVerifiableParameters(phone: phone, code: code)
        
        do {
            try otpVerifiableParameters.validate()
        } catch {
            BaseAnalytics.track(event: self.verifyOTP, properties: [self.failure: AuthErrorResponse.matchError().message])
            return Fail(error: AuthErrorResponse.matchError()).eraseToAnyPublisher()
        }
        
        var timeStamp: Int = 0
        var sign: String = ""
        do {
            timeStamp = Int(Date().timeIntervalSince1970)
            sign = try signature.sign(phone: phone, type: OTPType.registration.rawValue, timestampInSeconds: timeStamp)
        } catch {
            BaseAnalytics.track(event: self.verifyOTP, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
        }
        
        do {
            let body = OTPVerifiableBody(
                phone: phone,
                deviceId: deviceID,
                mode: OTPMode.sms,
                type: OTPType.registration,
                timestamp: timeStamp,
                otp: code,
                sign: sign
            )
            
            BaseAnalytics.track(event: self.verifyOTP, properties: [self.request: body.toDictionary().toMixpanelType()])
            
            return authAPIClient.verifyOTP(header: nil, body: body.toDictionary())
                .tryMap { resDTO in
                    try? self.gamePlayerStorage.savePhoneNumber(otpVerifiableParameters.phone)
                    
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

    func logout() -> AnyPublisher<DatalessServerResponse, Error> {
        do {
            try SensitiveDataManager.shared.delete(for: .otpVerifiedToken)
            let response = DatalessServerResponse(status: 1, message: "Success")
            return Just(response)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    func isAuthenticated() -> Bool {
        false
    }
    
    func getPhoneNumber() throws -> String? {
        try gamePlayerStorage.getPhoneNumber()
    }
}
