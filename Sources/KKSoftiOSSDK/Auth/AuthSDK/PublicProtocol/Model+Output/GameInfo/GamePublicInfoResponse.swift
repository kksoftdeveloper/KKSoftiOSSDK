//
//  File.swift
//  AuthSDK
//
//  Created by Admin on 5/13/25.
//

import Foundation

public struct GamePublicInfoResponse: Codable {
    public let fanpage: String
    public let phoneNumber: String
    
    private enum CodingKeys: String, CodingKey {
        case fanpage
        case phoneNumber
    }
}
