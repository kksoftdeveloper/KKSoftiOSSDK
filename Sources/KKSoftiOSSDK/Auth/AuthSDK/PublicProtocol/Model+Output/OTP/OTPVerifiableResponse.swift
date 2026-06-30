//
//  OTPVerifiableResponse.swift
//  AuthSDK
//

import Foundation

public struct OTPVerifiableResponse: Codable {
    let code: Int
    let message: String
    let otpVerifiedToken: String?
}
