//
//  GameInfoInput.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

public struct GamePlayerInput: Codable, Equatable, Hashable  {
    public let phoneNumber: String
    public let isGuest: Bool
}
