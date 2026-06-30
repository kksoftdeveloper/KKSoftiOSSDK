//
//  AuthErrorResponse.swift
//  AuthSDK
//

import Foundation

public struct AuthErrorResponse: Error, Decodable {
    public let message: String
    public let code: AuthErrorCodeResponse
    
    private enum CodingKeys: String, CodingKey {
        case message
        case code = "status"
    }
    
    private init(message: String, code: AuthErrorCodeResponse) {
        self.message = message
        self.code = code
    }
    
    // Convenience factory methods
    public static func success() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.Success.localizedDescription, code: .Success)
    }
    
    public static func matchError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.MatchError.localizedDescription, code: .MatchError)
    }
    
    public static func otpError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.OTPError.localizedDescription, code: .OTPError)
    }

    public static func otpExpired() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.OTPExpired.localizedDescription, code: .OTPExpired)
    }

    public static func otpRequestManyTime() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.OTPRequestManyTime.localizedDescription, code: .OTPError)
    }
    
    public static func otpInvalid() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.OTPInvalid.localizedDescription, code: .OTPInvalid)
    }
    
    public static func duplicatedPhoneError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.DulicatedPhoneError.localizedDescription, code: .DulicatedPhoneError)
    }
    
    public static func invalidPhoneError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.InvalidPhoneError.localizedDescription, code: .InvalidPhoneError)
    }
    
    public static func tokenExpired() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.TokenExpired.localizedDescription, code: .TokenExpired)
    }

    public static func accountNotExist() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.AccountNotExist.localizedDescription, code: .AccountNotExist)
    }

    public static func accountDeactivated() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.AccountDeactivated.localizedDescription, code: .AccountDeactivated)
    }
    
    public static func userBlocked() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.UserBlocked.localizedDescription, code: .UserBlocked)
    }

    public static func unauthenticated() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.Unauthorized.localizedDescription, code: .Unauthorized)
    }
    
    public static func unsupportedRequest() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.UnknownSupported.localizedDescription, code: .UnknownSupported)
    }
    
    public static func appNotFound() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.AppNotFound.localizedDescription, code: .AppNotFound)
    }
    
    public static func appNotConfigured() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.AppNotConfigured.localizedDescription, code: .AppNotConfigured)
    }
    
    public static func appNotConfiguredGame() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.AppNotConfiguredGame.localizedDescription, code: .AppNotConfiguredGame)
    }

    public static func appNotConfiguredGameServer() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.AppNotConfiguredGameServer.localizedDescription, code: .AppNotConfiguredGameServer)
    }
    
    public static func appNotConfiguredFacebook() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.AppNotConfiguredFacebook.localizedDescription, code: .AppNotConfiguredFacebook)
    }
    
    public static func appNotConfiguredGoogle() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.AppNotConfiguredGoogle.localizedDescription, code: .AppNotConfiguredGoogle)
    }
    
    public static func unknownError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.UnknownError.localizedDescription, code: .UnknownError)
    }
    
    public static func newPasswordRepeated() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.NewPassordRepeated.localizedDescription, code: .NewPassordRepeated)
    }
    
    public static func socialUserCancels() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.SocialUserCancels.localizedDescription, code: .SocialUserCancels)
    }
    
    public static func characterNotFound() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.CharacterNotFound.localizedDescription, code: .CharacterNotFound)
    }
    
    public static func invalidSignature() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.SDKSignatureError.localizedDescription, code: .SignatureError)
    }
    
    public static func facebookUnknownError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.FacebookUnknownError.localizedDescription, code: .FacebookUnknownError)
    }
    
    public static func facebookAuthenticateError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.FacebookAuthenticateError.localizedDescription, code: .FacebookAuthenticateError)
    }
    
    public static func googleUnknownError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.GoogleUnknownError.localizedDescription, code: .GoogleUnknownError)
    }
    
    public static func googleAuthenticateError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.GoogleAuthenticateError.localizedDescription, code: .GoogleAuthenticateError)
    }
    
    public static func sdkNotInitialized() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.SDKNotInitialized.localizedDescription, code: .SDKNotInitialized)
    }
    
    public static func sdkSignatureError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.SDKSignatureError.localizedDescription, code: .SDKSignatureError)
    }
    
    public static func socialAccountLinked() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.SocialAccountLinked.localizedDescription, code: .SocialAccountLinked)
    }
    
    public static func passwordValidationError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.SocialAccountLinked.localizedDescription, code: .SocialAccountLinked)
    }
    
    public static func invalidPhoneOrPasswordError() -> AuthErrorResponse {
        return AuthErrorResponse(message: AuthErrorCodeResponse.InvalidPhoneOrPassword.localizedDescription, code: .InvalidPhoneOrPassword)
    }
}


public enum AuthErrorCodeResponse: Int, Decodable, Identifiable {
    case Success = 1
    case MatchError = 0 // Some error from given parameters
    case OTPError = -1 // Failed to verify OTP
    case OTPInvalid = -10 // Invalid OTP. Please try again.
    case OTPExpired = -81 // Invalid OTP. Please try again.
    case OTPRequestManyTime = -80 // Failed to verify OTP
    case NewPassordRepeated = -60 // Failed to verify OTP
    case PasswordValidationError = -110 // Local Password Validation Error
    case SignatureError = -100 // Invalid signature detected.
    case DulicatedPhoneError = -2 // Phone number has been existed
    case InvalidPhoneError = -3 // Phone number has not signed up or OTP has not verified successful
    case SocialAccountLinked = -20 // Social account is already linked to another one
    case AccountNotExist = -30 // Account is not registered
    case TokenExpired = -200 // Access token has expired
    case CharacterNotFound = -201 // Character Not Found
    case Unauthorized = -401 // Unauthenticated
    case UnknownSupported = -405 // Unsupported the request
    case UserBlocked = -4004 // User is Blocked
    case AccountDeactivated = -404 // Account Not Found
    case AppNotFound = -1001 // App game has not registerd
    case AppNotConfigured = -1002 // App has not configured Game UUID
    case AppNotConfiguredGame = -1003 // App has not configured Game ID
    case AppNotConfiguredGameServer = -1004 // App has not configured Game Server or User has not picked up Server to play
    case AppNotConfiguredFacebook = -1005 // App has not completed configuration for Facebook Login
    case AppNotConfiguredGoogle = -1006 // App has not completed configuration for Google Login
    case FacebookUnknownError = -2001 // Facebook Unknown Error
    case FacebookAuthenticateError = -2002 // Facebook Unknown Error
    case GoogleUnknownError = -3001 // Google Unknown Error
    case GoogleAuthenticateError = -3002 // Google Authenticate Error
    case SocialUserCancels = -4001 // Facebook/Google user has cancelled
    case SDKNotInitialized = -5001 // SDK has not initialized
    case SDKSignatureError = -5002 // Signature signs error
    case UnknownError = -500 // Something has gone badly
    case InvalidPhoneOrPassword = -300
    public var id: Int { rawValue }
}

extension AuthErrorCodeResponse {
    public var localizedDescription: String {
        switch self {
        case .Success:
            return "Success"
        case .MatchError:
            return "Some error from given parameters"
        case .PasswordValidationError:
            return "Passwords must match and meet criteria."
        case .OTPError:
            return "Failed to verify OTP"
        case .OTPExpired:
            return "OTP is expired"
        case .OTPRequestManyTime:
            return "Too many OTP requests"
        case .SignatureError:
            return "Invalid signature detected"
        case .DulicatedPhoneError:
            return "Phone number has been existed"
        case .InvalidPhoneError:
            return "Phone number has not signed up or OTP has not verified successful"
        case .AccountNotExist:
            return "Account is not registered"
        case .AccountDeactivated:
            return "Account is deleted or not registered"
        case .UserBlocked:
            return "User is blocked"
        case .OTPInvalid:
            return "OTP is invalid"
        case .TokenExpired:
            return "Token has expired"
        case .NewPassordRepeated:
            return "New password cannot be the same as the old password."
        case .Unauthorized:
            return "Unauthenticated"
        case .CharacterNotFound:
            return "Character not found"
        case .UnknownSupported:
            return "Unsupported the request"
        case .UnknownError:
            return "Something has gone badly"
        case .AppNotFound:
            return "App game has not registerd"
        case .AppNotConfigured:
            return "App has not completed configuration"
        case .AppNotConfiguredGame:
            return "App has not configured game"
        case .AppNotConfiguredGameServer:
            return "App has not configured game servers"
        case .AppNotConfiguredFacebook:
            return "App has not completed configuration for Facebook"
        case .AppNotConfiguredGoogle:
            return "App has not completed configuration for Google"
        case .SocialUserCancels:
            return "User has cancelled"
        case .FacebookUnknownError:
            return "Facebook Unknown Error"
        case .FacebookAuthenticateError:
            return "Facebook Authenticate Error"
        case .GoogleUnknownError:
            return "Google Unknown Error"
        case .GoogleAuthenticateError:
            return "Google Authenticate Error"
        case .SDKNotInitialized:
            return "SDK has not initialized"
        case .SDKSignatureError:
            return "SDK has signed incorrect"
        case .SocialAccountLinked:
            return "Account is already linked to another one."
        case .InvalidPhoneOrPassword:
            return "Invalid phone or password"
        }
    }
}
