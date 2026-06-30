//
//  GamePlayerStorage.swift
//  AuthSDK
//

import Foundation

protocol GamePlayerStorage {
    func savePhoneNumber(_ phoneNumber: String) throws
    func getPhoneNumber() throws -> String?
    
    func saveIsGuestUser(_ isGuestUser: Bool) throws
    func getIsGuestUser() throws -> Bool
    
    func saveIsNewUser(_ isNewUser: Bool) throws
    func getIsNewUser() throws -> Bool
    
    func clear() throws
}
