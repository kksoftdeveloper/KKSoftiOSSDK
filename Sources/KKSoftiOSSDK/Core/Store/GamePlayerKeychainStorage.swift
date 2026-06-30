//
//  GamePlayerKeychainStorage.swift
//  AuthSDK
//
//  Created by X on 5/1/25.
//

import Foundation

final class GamePlayerKeychainStorage: GamePlayerStorage {
    
    private let service = "com.dar.kksoftiossdksdk.data.securestorage.gameplayer"
    private let playerPhoneNumber = "PlayerPhoneNumber"
    private let guestUser = "GuestUser"
    private let newUser = "NewUser"
    private let timeToRemindLogin = "TimeToRemindLogin"
    
    func savePhoneNumber(_ phoneNumber: String) throws {
        try KeychainHelper.shared.save(phoneNumber.data(using: .utf8)!, service: service, account: playerPhoneNumber)
    }
    
    func getPhoneNumber() throws -> String? {
        guard let data = try KeychainHelper.shared.load(service: service, account: playerPhoneNumber) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    func saveIsGuestUser(_ isGuestUser: Bool) throws {
        let byte: UInt8 = isGuestUser ? 1 : 0
        let data = Data([byte])
        try KeychainHelper.shared.save(data, service: service, account: guestUser)
    }
    
    func getIsGuestUser() throws -> Bool {
        guard let data = try KeychainHelper.shared.load(service: service, account: guestUser),
              let byte = data.first
        else {
            return false
        }
        return byte == 1
    }
    
    func saveIsNewUser(_ isNewUser: Bool) throws {
        let byte: UInt8 = isNewUser ? 1 : 0
        let data = Data([byte])
        try KeychainHelper.shared.save(data, service: service, account: newUser)
    }
    
    func getIsNewUser() throws -> Bool {
        guard let data = try KeychainHelper.shared.load(service: service, account: newUser),
              let byte = data.first
        else {
            return false
        }
        return byte == 1
    }
    
    func clear() throws {
        try KeychainHelper.shared.delete(service: service, account: guestUser)
        try KeychainHelper.shared.delete(service: service, account: newUser)
        try KeychainHelper.shared.delete(service: service, account: playerPhoneNumber)
        try KeychainHelper.shared.delete(service: service, account: timeToRemindLogin)
    }
}
