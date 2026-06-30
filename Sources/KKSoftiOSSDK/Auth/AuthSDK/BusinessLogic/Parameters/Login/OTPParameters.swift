//
//  File.swift
//  AuthSDK
//

import Foundation

struct OTPSendableParameters: ParameterValidatable {
    
    let phone: String

    enum CodingKeys: String, CodingKey {
        case phone
    }

    func validate() throws {
        guard !phone.isEmpty else {
            throw ValidationError.phoneIsEmpty
        }
        
        guard phone.isValidPhoneNumber() else {
            throw ValidationError.phoneIsInvalid
        }
    }
}

struct OTPVerifiableParameters: ParameterValidatable {
    
    let phone: String
    let code: String

    enum CodingKeys: String, CodingKey {
        case phone
        case code
    }

    func validate() throws {
        guard !phone.isEmpty else {
            throw ValidationError.phoneIsEmpty
        }
        
        guard phone.isValidPhoneNumber() else {
            throw ValidationError.phoneIsInvalid
        }
        
        guard !code.isEmpty, code.count <= 6 else {
            throw ValidationError.otpCodeIsInvalid
        }
    }
}
