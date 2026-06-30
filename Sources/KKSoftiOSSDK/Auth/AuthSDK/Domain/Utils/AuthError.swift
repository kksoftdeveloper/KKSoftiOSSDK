//
//  AuthError.swift
//  AuthSDK
//

import Foundation

enum AuthErrorCode: Int, Identifiable {
    
    case MatchError = 0 // Some error from given parameters
    case OTPError = -1 // Failed to verify OTP
    case DulicatedPhoneError = -2 // Phone number has been existed
    case InvalidPhoneError = -3 // Phone number has not signed up or OTP has not verified successful
    case TokenExpired = -200 // access token has expired
    case UnknownSupported = -405 // unsupported the request
    case AppNotFound = -1001 // App game has not registerd

    case FacebookUnknownError = -2001 // Facebook Unknown Error
    case FacebookRequestLoginError = -2002 // Facebook Unknown Error
    case FacebookResultLoginError = -2003 // Facebook Unknown Error
    case FacebookResultReceiveLoginError = -2004 // Facebook Unknown Error
    
    case GoogleUnknownError = -3001 // Google user has cancelled
    case GoogleInvalidWindowError = -3002  // Google sets up badlly
    case GoogleNoResultError = -3003  // Google sets up badlly
    case GoogleReceiveResultError = -3004  // Google sets up badlly
    
    case SocialUserCancels = -4001 // Facebook/Google user has cancelled
    
    case SdkNotInitialized = -5001 // SDK has not initialized
    case SDKSignatureError = -5002 // SDK has signed incorrectly
    
    case UnknownError = -500 // Something has gone badly
    
    
    public var id: Int { rawValue }
}

extension AuthErrorCode {
    func toErrorDescription() -> String? {
        switch self {
        case .MatchError:
            return "Some error from given parameters"
        case .OTPError:
            return "Failed to verify OTP"
        case .DulicatedPhoneError:
            return "Phone number has been existed"
        case .InvalidPhoneError:
            return "Phone number has not signed up or OTP has not verified successful"
        case .TokenExpired:
            return "Access token has expired"
        case .UnknownSupported:
            return "Unsupported the request"
        case .UnknownError:
            return "Something has gone badly"
        case .SocialUserCancels:
            return "User has cancelled"
        case .FacebookUnknownError:
            return "Facebook Unknown Error"
        case .FacebookResultLoginError:
            return "Facebook Result Login Error"
        case .FacebookRequestLoginError:
            return "Facebook Request Login Error"
        case .FacebookResultReceiveLoginError:
            return "Facebook Receive Login Error"
        case .GoogleUnknownError:
            return "Google Unknown Error"
        case .GoogleInvalidWindowError:
            return "Google Invalid Window Error"
        case .GoogleNoResultError:
            return "Google No Result Error"
        case .GoogleReceiveResultError:
            return "Google Receive Result Error"
        case .AppNotFound:
            return "App game has not registerd"
        case .SdkNotInitialized:
            return "SDK has not initialized"
        case .SDKSignatureError:
            return "SDK has signed incorrect"
        }
    }
    
    func toResponseCode() -> AuthErrorCodeResponse {
            switch self {
            case .MatchError:
                return .MatchError
            case .OTPError:
                return .OTPError
            case .DulicatedPhoneError:
                return .DulicatedPhoneError
            case .InvalidPhoneError:
                return .InvalidPhoneError
            case .TokenExpired:
                return .TokenExpired
            case .UnknownSupported:
                return .UnknownSupported
            case .AppNotFound:
                return .AppNotFound
            case .UnknownError:
                return .UnknownError

            case .SdkNotInitialized:
                return .SDKNotInitialized

            case .SDKSignatureError:
                return .SDKSignatureError
                
            case .SocialUserCancels:
                return .SocialUserCancels

            case .GoogleInvalidWindowError, .GoogleUnknownError, .GoogleNoResultError, .GoogleReceiveResultError:
                return .GoogleUnknownError

            case .FacebookUnknownError, .FacebookRequestLoginError, .FacebookResultLoginError, .FacebookResultReceiveLoginError:
                return .FacebookUnknownError
            }
        }
}
