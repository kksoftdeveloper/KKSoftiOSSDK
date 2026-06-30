//
//  RequestOTP.swift
//  AuthSDK
//

import Foundation

struct OTPSendableBody: Encodable {
    let phone: String
    let deviceId: String
    let mode: OTPMode // SMS or EMAIL
    let type: OTPType // REGISTRATION or FORGOTPASSWORD
    let timestamp: Int
    let sign: String
}
