//
//  OTPSendableModel.swift
//  AuthSDK
//

import Foundation

struct OTPSendableModel {
    let otpSent: Bool
    let expiresInSeconds: Int
    let retryAfterSeconds: Int
}

extension OTPSendableModel {
    
    func toResponse() -> OTPSendableResponse {
        return OTPSendableResponse(otpSent: otpSent, retryAfterSeconds: retryAfterSeconds, expiresInSeconds: expiresInSeconds)
    }

    func sampleInstance() -> OTPSendableModel {
        return OTPSendableModel(
            otpSent: true,
            expiresInSeconds: 300,
            retryAfterSeconds: 60
        )
    }
}
