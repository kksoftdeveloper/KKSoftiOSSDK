//
//  GameInfo.swift
//  AuthSDK
//

import Foundation


public struct GameServerInfoResponse: Codable, Identifiable  {
    public let serverId: Int
    public let serverName: String
    public let serverClientId: String?
    public let serverClientName: String?
    public let serverStatus: ServerStatusResponse
    
    public var id: String { "\(serverId)" }
}

public enum ServerStatusResponse: String, Codable {
    case online = "ONLINE"
    case offline = "OFFLINE"
    case unknown = "UNKNOWN"
    
}
