//
//  TransactionStatus.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

enum TransactionStatus: String {
    case success = "SUCCESS"
    case availible = "AVAILABLE"
    case unavailible = "UNAVAILABLE"
    case pending = "PENDING"
    case timeout = "TIMEOUT"
}
