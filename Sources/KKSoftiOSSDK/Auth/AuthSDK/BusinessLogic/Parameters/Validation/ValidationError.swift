//
//  ValidationError.swift
//  AuthSDK
//

import Foundation

enum ValidationError: LocalizedError {
    case emailIsEmpty
    case emailIsInvalid
    case phoneIsEmpty
    case phoneIsInvalid
    case otpCodeIsInvalid
    case passwordIsEmpty
    case passwordIsTooShort
    case facebookClientIDMissing
    case facebookClientSecretMissing
    case googleClientIDMissing
    case googleSchemaURLMissing
    
    var errorDescription: String? {
        switch self {
        case .phoneIsEmpty:
            return "Phone number cannot be empty."
        case .phoneIsInvalid:
            return "Phone number is invalid."
        case .emailIsEmpty:
            return "Email cannot be empty."
        case .emailIsInvalid:
            return "Email is invalid."
        case .otpCodeIsInvalid:
            return "OTP code is invalid."
        case .passwordIsEmpty:
            return "Password cannot be empty."
        case .passwordIsTooShort:
            return "Password must contain at least 8 characters."
        case .facebookClientIDMissing:
            return "Facebook Client ID is missing."
        case .facebookClientSecretMissing:
            return "Facebook Client Secret is missing."
        case .googleClientIDMissing:
            return "Google Client ID is missing."
        case .googleSchemaURLMissing:
            return "Google URL Schema is missing."
        }
    }
}
