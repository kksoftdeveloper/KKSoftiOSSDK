//
//  AppInfoInput.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

public struct AppInfoInput: Codable, Equatable, Hashable {
    public let packageName: String
    public let appVersion: String
}
