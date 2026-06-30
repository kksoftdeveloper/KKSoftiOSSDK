//
//  OTPServerResponseDTO.swift
//  AuthSDK
//

import Foundation

typealias OTPSendableServerResponse = APIResponse<OTPSendableServerResponseDTO>

struct OTPSendableServerResponseDTO: Decodable {
    let otpSent: Bool
    let expiresInSeconds: Int
    let retryAfterSeconds: Int
}

extension OTPSendableServerResponseDTO {
    
    func toModel() -> OTPSendableModel {
        return OTPSendableModel(
            otpSent: otpSent, expiresInSeconds: expiresInSeconds, retryAfterSeconds: retryAfterSeconds
        )
    }
}
