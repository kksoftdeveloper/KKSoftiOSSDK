//
//  SignupManager.swift
//  AuthSDK
//

import Foundation
import Combine

public protocol SignupManager {
    func signup(phone: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<AuthSessionResponse, Error>
    func signup(phone: String, password: String, otpVerifiedToken: String?, accountInformation: AccountInformation?) -> AnyPublisher<AuthSessionResponse, Error>
    func linkToNewAccount(phone: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<AuthSessionResponse, Error>
    func updateInfo(_ data: AccountInformation) -> AnyPublisher<Bool, Error>
    func getPhoneNumber() throws -> String?
    func getServerId() -> Int?
    func getGameId() -> Int?
}
