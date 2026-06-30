//
//  GuestLoginManager.swift
//  AuthSDK
//

import Foundation
import Combine

public protocol GuestLoginManager {
    func login() -> AnyPublisher<AuthSessionResponse, Error>

    func logout() -> AnyPublisher<DatalessServerResponse, Error>
    
    func getAuthSesssion() -> AnyPublisher<AuthSessionResponse, Error>
    
    func getPhoneNumber() throws -> String?
    
    func getServerId() -> Int?
    
    func getGameId() -> Int?
    
    func isGuestUser() -> Bool
}
