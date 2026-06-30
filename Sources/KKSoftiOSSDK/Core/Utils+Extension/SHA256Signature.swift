//
//  SignatureSHA256.swift
//  AuthSDK
//

import Foundation
import CryptoKit

final class SHA256Signature: Signature, DeviceIdentifiable, SDKInfo {
    
    // Link account with phone
    // deviceId|type|phone|password|otpVerifiedToken|secretKey
    func sign(type: String, phone: String, password: String, otpVerifiedToken: String) throws -> String {
        let combined = "\(deviceID)|\(type)|\(phone)|\(password)|\(otpVerifiedToken)|\(deviceSecretKey)"
        return sha256Base64Safe(combined)
    }
    
    // guest login
    // deviceId|type|platform|sdkVersion|appVersion|gameId|secretKey
    func sign(type: String) throws -> String {
        guard let gameID = gameInfoStorage.gameID else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        guard let appVersion = gameInfoStorage.appVersion else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        let combined = "\(deviceID)|\(type)|\(platform)|\(versionName)|\(appVersion)|\(gameID)|\(deviceSecretKey)"
        return sha256Base64Safe(combined)
    }
    
    // refresh token
    // deviceId|platform|sdkVersion|appVersion|refreshToken|secretKey
    func sign(refreshToken: String) throws -> String {
        guard let appVersion = gameInfoStorage.appVersion else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        let combined = "\(deviceID)|\(platform)|\(versionName)|\(appVersion)|\(refreshToken)|\(deviceSecretKey)"
        return sha256Base64Safe(combined)
    }
    
    // Link account with social
    // deviceId|token|type|secretKey
    func sign(token: String, type: String) throws -> String {
        let combined = "\(deviceID)|\(token)|\(type)|\(deviceSecretKey)"
        return sha256Base64Safe(combined)
    }
    
    func sign(phone: String, type: String, otp: String, timestampInSeconds: Int) throws -> String {
        let combined = "\(deviceID)|\(phone)|\(type)|\(otp)|\(timestampInSeconds)|\(deviceSecretKey)"
        
        return sha256Base64Safe(combined)
    }
    
    func sign(phone: String, type: String, timestampInSeconds: Int) throws -> String {
        let combined = "\(deviceID)|\(phone)|\(type)|\(timestampInSeconds)|\(deviceSecretKey)"
        
        return sha256Base64Safe(combined)
    }
    
    /**
     deviceId|gameId|type|phone|platform|sdkVersion|appVersion|secretKey
     phone login
     */
    func sign(phone: String, type: String) throws -> String {
        guard let gameID = gameInfoStorage.gameID else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        guard let appVersion = gameInfoStorage.appVersion else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        let combined = "\(deviceID)|\(gameID)|\(type)|\(phone)|\(platform)|\(versionName)|\(appVersion)|\(deviceSecretKey)"
        return sha256Base64Safe(combined)
    }
    
    /**
    deviceId|type|token|platform|sdkVersion|appVersion|gameId|secretKey
    social login
     */
    func sign(type: String, token: String) throws -> String {
        guard let gameID = gameInfoStorage.gameID else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        guard let appVersion = gameInfoStorage.appVersion else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        let combined = "\(deviceID)|\(type)|\(token)|\(platform)|\(versionName)|\(appVersion)|\(gameID)|\(deviceSecretKey)"
        return sha256Base64Safe(combined)
    }
    
    // For get game-info
    // deviceId|packageName|platform|appVersion|sdkVersion|timestamp|secretKey
    func sign(timestampInSeconds: Int) throws -> String {
        guard let packageName = gameInfoStorage.packageName else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        guard let appVersion = gameInfoStorage.appVersion else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        
        let combined = "\(deviceID)|\(packageName)|\(platform)|\(appVersion)|\(versionName)|\(timestampInSeconds)|\(deviceSecretKey)"
        
        return sha256Base64Safe(combined)
    }
    
    // phone register
    // deviceId|gameId|phone|password|otpVerifiedToken|platform|sdkVersion|appVersion|secretKey
    func sign(phone: String, password: String, otpVerifiedToken: String) throws -> String {
        guard let gameID = gameInfoStorage.gameID else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        guard let appVersion = gameInfoStorage.appVersion else {
            throw AuthErrorModel.sdkNotInitialized()
        }
        let combined = "\(deviceID)|\(gameID)|\(phone)|\(password)|\(otpVerifiedToken)|\(platform)|\(versionName)|\(appVersion)|\(deviceSecretKey)"
        
        return sha256Base64Safe(combined)
    }
    

    func updateIfo(_ info: AccountInformation) throws -> String {
        return sha256Base64Safe(info.toDictionary().description)
    }
    
    /**
     sku|price|gameId|serverId|platform|appVersion|sdkVersion|secretKey
     validate game package
     */
    func sign(sku: String, price: Int, serverId: String) throws -> String {
        guard let gameID = gameInfoStorage.gameID, let appVersion = gameInfoStorage.appVersion, let _ = gameInfoStorage.gameUUID else {
            throw PaymentError.sdkNotInitialized()
        }
        
        let combined =  "\(sku)|\(price)|\(gameID)|\(serverId)|\(platform)|\(appVersion)|\(versionName)|\(deviceSecretKey)"
        return sha256Base64Safe(combined)
    }
    
    /**
     sku|transactionId|gameId|serverId|platform|appVersion|sdkVersion|secretKey
     verify game package purchase
     */
    func sign(sku: String, transactionId: String, serverId: String, purchaseToken: String) throws -> String {
        guard let gameID = gameInfoStorage.gameID, let appVersion = gameInfoStorage.appVersion else {
            throw PaymentError.sdkNotInitialized()
        }
        
        let combined = "\(sku)|\(transactionId)|\(gameID)|\(serverId)|\(platform)|\(appVersion)|\(versionName)|\(deviceSecretKey)"
        return sha256Base64Safe(combined)
    }
    
    private func sha256Base64Safe(_ combined: String) -> String {
        debugPrint("combined: \(combined)")

        let inputData = Data(combined.utf8)
        let hash = SHA256.hash(data: inputData)
        let hashData = Data(hash)
        var base64 = hashData.base64EncodedString()
        base64 = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return base64
    }
    
    private var gameInfoStorage: GameInfoStorage
    
    init(gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage()) {
        self.gameInfoStorage = gameInfoStorage
    }
}
