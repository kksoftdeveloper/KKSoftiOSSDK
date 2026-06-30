//
//  OTPServerResponseDTO.swift
//  AuthSDK
//

import Foundation

typealias OTPResendableServerResponse = APIResponse<OTPResendableServerResponseDTO>

struct OTPResendableServerResponseDTO: Decodable {
    
}

extension OTPResendableServerResponseDTO {
    
    func toModel() -> OTPResendableModel {
        return OTPResendableModel()
    }
}
