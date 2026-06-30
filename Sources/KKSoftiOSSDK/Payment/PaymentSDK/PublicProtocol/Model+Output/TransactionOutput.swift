//
//  TransactionOutput.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

struct TransactionOutput: Codable {
    let id: String
    let amount: Double
    let currency: String
    let status: String
}
