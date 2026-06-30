//
//  RequestOTP.swift
//  AuthSDK
//

import Foundation

struct OTPResendableHeader: Encodable {
    
}

struct OTPResendableBody: Encodable {
    let phone: String
}
