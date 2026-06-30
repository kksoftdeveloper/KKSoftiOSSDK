//
//  PhoneSignupParameters.swift
//  AuthSDK
//

import Foundation

struct PhoneSignupParameters: ValidatedSignupParameters {
    let provider = "phone"
    let phone: String
    let password: String

    func validate() throws {
        guard !phone.isEmpty else {
            throw ValidationError.phoneIsEmpty
        }
        
        guard phone.isValidPhoneNumber() else {
            throw ValidationError.phoneIsInvalid
        }
        
        guard !password.isEmpty else {
            throw ValidationError.passwordIsEmpty
        }
        guard password.isStrongPassword() else {
            throw ValidationError.passwordIsTooShort
        }
    }
}
