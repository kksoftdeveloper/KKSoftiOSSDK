//
//  OTPSendableResponse.swift
//  AuthSDK
//

import Foundation

public struct OTPSendableResponse: Codable, Equatable, Hashable {
    let otpSent: Bool
    let retryAfterSeconds: Int
    let expiresInSeconds: Int
}
