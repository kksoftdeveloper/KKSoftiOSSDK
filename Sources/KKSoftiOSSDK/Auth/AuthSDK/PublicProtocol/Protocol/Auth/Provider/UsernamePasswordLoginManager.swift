//
//  UsernamePasswordLoginManager.swift
//  AuthSDK
//

import Foundation
import Combine

public protocol UsernamePasswordLoginManager {
    func login(phoneNumber: String, password: String) -> AnyPublisher<AuthSessionResponse, Error> 

    func logout() -> AnyPublisher<DatalessServerResponse, Error> 
    
    func getAuthSesssion() -> AnyPublisher<AuthSessionResponse, Error>
    
    func getPhoneNumber() throws -> String?
    
    func getServerId() -> Int? 
    
    func getGameId() -> Int?
    
    func getCharacter(gameId: Int, serverId: Int) -> AnyPublisher<Void, Error>
}
