//
//  VerifyOTP.swift
//  AuthSDK
//

import Foundation

struct OTPVerifiableBody: Encodable {
    let phone: String
    let deviceId: String
    let mode: OTPMode // SMS or EMAIL
    let type: OTPType // REGISTRATION or FORGOTPASSWORD
    let timestamp: Int
    let otp: String
    let sign: String
}
