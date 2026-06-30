//
//  PaymentError.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

public struct PaymentError: Error, Decodable {
    public let message: String
    public let code: PaymentErrorCode
    
    private enum CodingKeys: String, CodingKey {
        case message
        case code = "status"
    }
    
    private init(message: String, code: PaymentErrorCode) {
        self.message = message
        self.code = code
    }
    
    // Convenience factory methods
    public static func success() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.Success.localizedDescription, code: .Success)
    }
    
    public static func matchError() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.MatchError.localizedDescription, code: .MatchError)
    }
    
    public static func tokenExpired() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.TokenExpired.localizedDescription, code: .TokenExpired)
    }
    
    public static func refreshTokenExpired() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.RefreshTokenExpired.localizedDescription, code: .RefreshTokenExpired)
    }
    
    public static func accountNotExist() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.AccountNotExist.localizedDescription, code: .AccountNotExist)
    }

    public static func unauthenticated() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.Unauthorized.localizedDescription, code: .Unauthorized)
    }

    public static func characterNotFound() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.CharacterNotFound.localizedDescription, code: .CharacterNotFound)
    }
    
    public static func unsupportedRequest() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.UnknownSupported.localizedDescription, code: .UnknownSupported)
    }
    
    public static func appNotFound() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.AppNotFound.localizedDescription, code: .AppNotFound)
    }
    
    public static func appNotConfigured() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.AppNotConfigured.localizedDescription, code: .AppNotConfigured)
    }
    
    public static func unknownError() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.UnknownError.localizedDescription, code: .UnknownError)
    }
    
    public static func invalidResponse() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.InvalidResponse.localizedDescription, code: .InvalidResponse)
    }
    
    public static func sdkNotInitialized() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.SDKNotInitialized.localizedDescription, code: .SDKNotInitialized)
    }
    
    public static func sdkSignatureError() -> PaymentError {
        return PaymentError(message: PaymentErrorCode.SDKSignatureError.localizedDescription, code: .SDKSignatureError)
    }
    
    public static func productNotFound() -> PaymentError {
        PaymentError(message: PaymentErrorCode.ProductNotFound.localizedDescription, code: .ProductNotFound)
    }
    
    public static func invalidSKU() -> PaymentError {
        PaymentError(message: PaymentErrorCode.InvalidSKU.localizedDescription, code: .InvalidSKU)
    }
    
    public static func inactivedSKU() -> PaymentError {
        PaymentError(message: PaymentErrorCode.InactivedSKU.localizedDescription, code: .InactivedSKU)
    }

    public static func purchaseCancelled() -> PaymentError {
        PaymentError(message: PaymentErrorCode.PurchaseCancelled.localizedDescription, code: .PurchaseCancelled)
    }

    public static func purchaseFailed(reason: String) -> PaymentError {
        PaymentError(message: reason, code: .PurchaseFailed)
    }
}


public enum PaymentErrorCode: Int, Decodable, Identifiable {
    case Success = 1
    case MatchError = 0 // Some error from given parameters
    case AccountNotExist = -30 // Account is not registered
    case TokenExpired = -200 // Access token has expired
    case RefreshTokenExpired = -20000 // Unauthenticated
    case CharacterNotFound = -201 // Character not found
    case Unauthorized = -401 // Unauthenticated
    case UnknownSupported = -405 // Unsupported the request
    case AppNotFound = -1001 // App game has not registerd
    case AppNotConfigured = -1002 // App has not configured Game UUID
    case UnknownError = -500 // Something has gone badly
    case InvalidResponse = -5000 // Invalid reponse format
    case SDKNotInitialized = -5001 // SDK has not initialized
    case SDKSignatureError = -5002 // Signature signs error
    
    // Apple IAP specific
    case ProductNotFound = -6001
    case PurchaseCancelled = -6002
    case PurchaseFailed = -6003
    case InvalidSKU = -6004
    case InactivedSKU = -6005
    
    public var id: Int { rawValue }
}

extension PaymentErrorCode {
    public var localizedDescription: String {
        switch self {
        case .Success:
            return "Success"
        case .MatchError:
            return "Some error from given parameters"
        case .AccountNotExist:
            return "Account is not registered"
        case .TokenExpired:
            return "Token has expired"
        case .RefreshTokenExpired:
            return "Refresh token has expired"
        case .CharacterNotFound:
            return "Character not found"
        case .Unauthorized:
            return "Unauthenticated"
        case .UnknownSupported:
            return "Unsupported the request"
        case .UnknownError:
            return "Something has gone badly"
        case .AppNotFound:
            return "App game has not registerd"
        case .AppNotConfigured:
            return "App has not completed configuration"
        case .InvalidResponse:
            return "P-Response is invalid format"
        case .SDKNotInitialized:
            return "P-SDK has not initialized"
        case .SDKSignatureError:
            return "P-Signature has been invalid"
        case .ProductNotFound:
            return "Product not found"
        case .PurchaseCancelled:
            return "Purchase was cancelled"
        case .PurchaseFailed:
            return "Purchase failed due to unknown error"
        case .InvalidSKU:
            return "Invalid SKU"
        case .InactivedSKU:
            return "Inactived SKU"
        }
    }
}
