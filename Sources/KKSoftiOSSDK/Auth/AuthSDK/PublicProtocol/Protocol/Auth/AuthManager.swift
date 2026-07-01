//
//  AuthManager.swift
//  AuthSDK
//

import Foundation
import Combine

public protocol AuthManager {
    var appVersion: String { get }
    var osVersion: String { get }
    
    func initSDK(
        packageName: String,
        appVersion: String,
        serverId: Int
    ) -> AnyPublisher<AuthInitResponse, Error>
    
    func login(email: String, password: String) -> AnyPublisher<AuthSessionResponse, Error>
    func login(phoneNumber: String, password: String) -> AnyPublisher<AuthSessionResponse, Error>
    func loginWithGoogleAccount() -> AnyPublisher<AuthSessionResponse, Error>
    func loginWithFacebookAccount() -> AnyPublisher<AuthSessionResponse, Error>
    func loginWithAppleAccount() -> AnyPublisher<AuthSessionResponse, Error>
    func loginWithGuest() -> AnyPublisher<AuthSessionResponse, Error>
    
    func refreshToken() -> AnyPublisher<AuthSessionResponse, Error>
    func signup(phoneNumber: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<AuthSessionResponse, Error>
    func signup(phoneNumber: String, password: String, otpVerifiedToken: String?, accountInformation: AccountInformation?) -> AnyPublisher<AuthSessionResponse, Error>

    func linkToNewAccount(
        phoneNumber: String,
        password: String,
        otpVerifiedToken: String?) -> AnyPublisher<AuthSessionResponse, Error>
    
    func updateAccountInfo(data: AccountInformation) -> AnyPublisher<Bool, Error>
    
    func linkToGoogleAccount() -> AnyPublisher<AuthSessionResponse, Error>
    func linkToFacebookAccount() -> AnyPublisher<AuthSessionResponse, Error>
    
    func forgetPassword(phoneNumber: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<DatalessServerResponse, Error>
    
    func getGameInfo() -> AnyPublisher<GameInfoResponse, Error>
    func getGamePublicInfo() -> GamePublicInfoResponse
    func getGameServerLists() -> AnyPublisher<[GameServerInfoResponse], Error>
    func updateGameServer(selectedGameServer: GameServerInfoResponse) -> AnyPublisher<String, any Error>
    
    func requestOTP(phone: String) -> AnyPublisher<OTPSendableResponse, Error>
    func verifyOTP(code: String) -> AnyPublisher<OTPVerifiableResponse, Error>
    
    func requestOTPForgetPassword(phone: String) -> AnyPublisher<OTPSendableResponse, Error>
    func verifyOTPForgetPassword(phone: String, code: String) -> AnyPublisher<OTPVerifiableResponse, Error>
    
    func logout() -> AnyPublisher<DatalessServerResponse, Error>
    func getAuthSesssion() -> AnyPublisher<AuthSessionResponse, Error>
    func getDeviceID() -> String
    func getPhoneNumber() -> String
    func getServerId() -> Int?
    func getGameId() -> Int?
    
    func deactivateAccount() -> AnyPublisher<DatalessServerResponse, Error>
    func isGuestUser() -> Bool
}
