//
//  OTPVerifiableModel.swift
//  AuthSDK
//

import Foundation

struct OTPVerifiableModel {
    let otpVerifiedToken: String?
    let expiresInSeconds: Int
}

extension OTPVerifiableModel {
    
    func toSuccessResponse() -> OTPVerifiableResponse {
        return OTPVerifiableResponse(
            code: 200,
            message: "Success",
            otpVerifiedToken: otpVerifiedToken
        )
    }
    
    func toFailureResponse() -> OTPVerifiableResponse {
        return OTPVerifiableResponse(
            code: -1,
            message: "Failure",
            otpVerifiedToken: nil
        )
    }
    
    func sampleInstance() -> OTPVerifiableModel {
        return OTPVerifiableModel(
            otpVerifiedToken: "base64OrJwtString...",
            expiresInSeconds: 300
        )
    }
}
