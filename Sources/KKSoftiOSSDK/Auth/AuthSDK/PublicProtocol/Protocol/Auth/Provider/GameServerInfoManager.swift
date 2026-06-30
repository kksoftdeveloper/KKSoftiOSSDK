//
//  GameServerInfoManager.swift
//  AuthSDK
//

import Foundation
import Combine

public typealias GameUUID = String

public protocol GameServerInfoManager {
    
    func getGameInfo() -> AnyPublisher<GameInfoResponse, Error>
    
    func getGameServers() -> AnyPublisher<[GameServerInfoResponse], Error>
    
    func getAuthenticatedGameServers() -> AnyPublisher<[GameServerInfoResponse], any Error>
    
    func updateGameServer(selectedServerId: Int, selectedServerName: String) -> AnyPublisher<GameUUID, Error>
}
