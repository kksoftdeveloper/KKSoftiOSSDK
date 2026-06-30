//
//  AuthError.swift
//  AuthSDK
//

import Foundation

struct AuthErrorModel : Error {
    let message: String
    let code: AuthErrorCode
    
    // Private initializer to enforce controlled initialization
    private init(code: AuthErrorCode) {
        self.code = code
        self.message = code.toErrorDescription() ?? "Unknown error occurred"
    }
    
    // Factory methods for all instances
    static func matchError() -> AuthErrorModel {
        AuthErrorModel(code: .MatchError)
    }
    
    static func otpError() -> AuthErrorModel {
        AuthErrorModel(code: .OTPError)
    }
    
    static func duplicatedPhoneError() -> AuthErrorModel {
        AuthErrorModel(code: .DulicatedPhoneError)
    }
    
    static func invalidPhoneError() -> AuthErrorModel {
        AuthErrorModel(code: .InvalidPhoneError)
    }
    
    static func tokenExpired() -> AuthErrorModel {
        AuthErrorModel(code: .TokenExpired)
    }
    
    static func unsupportedRequest() -> AuthErrorModel {
        AuthErrorModel(code: .UnknownSupported)
    }
    
    static func appNotFound() -> AuthErrorModel {
        AuthErrorModel(code: .AppNotFound)
    }
    
    static func unknownError() -> AuthErrorModel {
        AuthErrorModel(code: .UnknownError)
    }
    
    static func socialUserCancels() -> AuthErrorModel {
        AuthErrorModel(code: .SocialUserCancels)
    }
    
    static func facebookUnknownError() -> AuthErrorModel {
        AuthErrorModel(code: .FacebookUnknownError)
    }
    
    static func facebookRequestLoginError() -> AuthErrorModel {
        AuthErrorModel(code: .FacebookRequestLoginError)
    }
    
    static func facebookResultLoginError() -> AuthErrorModel {
        AuthErrorModel(code: .FacebookResultLoginError)
    }

    static func facebookResultReceiveError() -> AuthErrorModel {
        AuthErrorModel(code: .FacebookResultReceiveLoginError)
    }
    
    static func googleUnknownError() -> AuthErrorModel {
        AuthErrorModel(code: .GoogleUnknownError)
    }
    
    static func googleNoResultError() -> AuthErrorModel {
        AuthErrorModel(code: .GoogleNoResultError)
    }
    
    static func googleInvalidWindowError() -> AuthErrorModel {
        AuthErrorModel(code: .GoogleInvalidWindowError)
    }
    
    static func googleReceiveResultError() -> AuthErrorModel {
        AuthErrorModel(code: .GoogleReceiveResultError)
    }
    
    static func sdkNotInitialized() -> AuthErrorModel {
        AuthErrorModel(code: .SdkNotInitialized)
    }
}

extension AuthErrorModel {
    
    func toResponse() -> AuthErrorResponse {
        switch self.code {
        case .MatchError:
                .matchError()
        case .OTPError:
                .otpError()
        case .DulicatedPhoneError:
                .duplicatedPhoneError()
        case .InvalidPhoneError:
                .invalidPhoneError()
        case .TokenExpired:
                .tokenExpired()
        case .UnknownSupported:
                .unsupportedRequest()
        case .AppNotFound:
                .appNotFound()
        case .UnknownError:
                .unknownError()
            
        case .SocialUserCancels:
                .socialUserCancels()
            
        case .SdkNotInitialized:
                .sdkNotInitialized()
            
        case .SDKSignatureError:
                .sdkSignatureError()
            
        case .GoogleUnknownError, .GoogleInvalidWindowError, .GoogleNoResultError, .GoogleReceiveResultError:
                .googleUnknownError()
    
        case .FacebookUnknownError, .FacebookRequestLoginError, .FacebookResultLoginError, .FacebookResultReceiveLoginError:
                .facebookUnknownError()
        }
    }
}


