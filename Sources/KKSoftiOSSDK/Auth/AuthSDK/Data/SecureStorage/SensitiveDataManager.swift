//
//  SensitiveDataManaget.swift
//  AuthSDK
//

import Foundation

final class SensitiveDataManager {
    private let service = "com.dar.authsdk.data.securestorage.sensitivedatamanager"

    static let shared = SensitiveDataManager()
    private init() { }

    enum DataKey: String {
        case facebookClientID
        case facebookClientSecret
        case googleClientID
        case googleURLSchema
        case otpVerifiedToken
    }
    
    private enum SecretKey: String {
        case deviceID = "com.dar.authsdk.data.securestorage.secret.deviceid"
    }
    
    func getDeviceID() throws -> String {
        if let existingDeviceID = try KeychainHelper.shared.loadString(service: service, account: SecretKey.deviceID.rawValue) {
            return existingDeviceID
        } else {
            let newDeviceID = UUID().uuidString
            try KeychainHelper.shared.saveString(newDeviceID, service: service, account: SecretKey.deviceID.rawValue)
            return newDeviceID
        }
    }

    func set(_ value: String, for key: DataKey) throws {
        try KeychainHelper.shared.saveString(value, service: service, account: key.rawValue)
    }

    func get(for key: DataKey) throws -> String? {
        return try KeychainHelper.shared.loadString(service: service, account: key.rawValue)
    }

    func delete(for key: DataKey) throws {
        try KeychainHelper.shared.delete(service: service, account: key.rawValue)
    }
}
