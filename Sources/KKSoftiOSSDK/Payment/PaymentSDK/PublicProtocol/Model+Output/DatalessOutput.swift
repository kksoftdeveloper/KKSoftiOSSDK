//
//  DatalessOutput.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

public struct DatalessOutput: Codable, Equatable, Hashable {
    let status: Int
    let message: String
}
