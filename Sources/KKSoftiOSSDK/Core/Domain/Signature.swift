//
//  Signature.swift
//  AuthSDK
//

import Foundation

protocol Signature {
    //auth
    // for get game-info request body
    func sign(timestampInSeconds: Int) throws -> String
    
    // for verify-otp request body
    // sha256Base64Safe(deviceId|phone|type|otp|timestamp|device-secret)
    func sign(phone: String, type: String, otp: String, timestampInSeconds: Int) throws -> String
    
    // for login request body
    // sha256Base64Safe(deviceId|phone|type|password|timestamp|device-secret)
    func sign(phone: String, type: String) throws -> String
    
    // social login
    // deviceId|type|token|platform|sdkVersion|appVersion|gameId|secretKey
    func sign(type: String, token: String) throws -> String
    
    // guest login
    // deviceId|type|platform|sdkVersion|appVersion|gameId|secretKey
    func sign(type: String) throws -> String
    
    // refresh token
    // deviceId|platform|sdkVersion|appVersion|refreshToken|secretKey
    func sign(refreshToken: String) throws -> String
    
    // for send-otp request body
    // sha256Base64Safe(deviceId|phone|type|timestamp|device-secret)
    func sign(phone: String, type: String, timestampInSeconds: Int) throws -> String
    
    // phone signup & link to new account with phone
    // deviceId|gameId|phone|password|otpVerifiedToken|platform|sdkVersion|appVersion|secretKey
    func sign(phone: String, password: String, otpVerifiedToken: String) throws -> String
    
    func updateIfo(_ info: AccountInformation) throws -> String
    
    // Link account with social
    // deviceId|token|type|secretKey
    func sign(token: String, type: String) throws -> String
    
    // Link account with phone
    // deviceId|type|phone|password|otpVerifiedToken|secretKey
    func sign(type: String, phone: String, password: String, otpVerifiedToken: String) throws -> String
    
    //payment
    
    func sign(sku: String, price: Int, serverId: String) throws -> String
    func sign(sku: String, transactionId: String, serverId: String, purchaseToken: String) throws -> String
    
    
}
