//
//  EmailLoginParameters.swift
//  AuthSDK
//

import Foundation

struct EmailLoginParameters: ValidatedLoginParameters {
    let provider = "email"
    let email: String
    let password: String

    func validate() throws {
        guard !email.isEmpty else {
            throw ValidationError.emailIsEmpty
        }
        guard !password.isEmpty else {
            throw ValidationError.passwordIsEmpty
        }
        guard password.isStrongPassword() else {
            throw ValidationError.passwordIsTooShort
        }
        guard email.isValidEmail() else {
            throw ValidationError.phoneIsEmpty
        }
    }
}
