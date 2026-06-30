//
//  ForgetPasswordManager.swift
//  AuthSDK
//
//  Created by X on 4/20/25.
//

import Foundation
import Combine

public protocol ForgetPasswordManager {
    func forgetPassword(phoneNumber: String, password: String, otpVerifiedToken: String?) -> AnyPublisher<DatalessServerResponse, Error>
    
    func requestOTP(phone: String) -> AnyPublisher<OTPSendableResponse, Error>
    
    func verifyOTP(phone: String, code: String) -> AnyPublisher<OTPVerifiableResponse , Error>
    
}
