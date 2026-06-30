//
//  OTPVerifiableServerResponseDTO.swift
//  AuthSDK
//

import Foundation


typealias OTPVerifiableServerResponse = APIResponse<OTPVerifiableServerResponseDTO>

struct OTPVerifiableServerResponseDTO: Decodable {
    let otpVerifiedToken: String?
    let expiresInSeconds: Int
}

extension OTPVerifiableServerResponseDTO {
    
    func toModel() -> OTPVerifiableModel {
        return OTPVerifiableModel(
            otpVerifiedToken: otpVerifiedToken,
            expiresInSeconds: expiresInSeconds
        )
    }
}
