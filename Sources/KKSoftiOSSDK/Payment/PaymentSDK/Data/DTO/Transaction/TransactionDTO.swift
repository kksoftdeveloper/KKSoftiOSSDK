//
//  TransactionDTO.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

struct TransactionDTO: Decodable {
    let id: String
    let amount: Double
    let currency: String
    let status: TransactionStatusDTO
    
    enum TransactionStatusDTO: String, Codable {
        case success = "SUCCESS"
        case availible = "AVAILABLE"
        case unavailible = "UNAVAILABLE"
        case pending = "PENDING"
        case timeout = "TIMEOUT"
    }
}

extension TransactionDTO.TransactionStatusDTO {
    func toModel() -> TransactionStatus {
        switch self {
        case .success:
            return .success
        case .availible:
            return .availible
        case .unavailible:
            return .unavailible
        case .pending:
            return .pending
        case .timeout:
            return .timeout
        }
    }
}

extension TransactionDTO {
    
    func toModel() -> TransactionModel {
        return TransactionModel(
            id: id, amount: amount, currency: currency, status: status.toModel()
        )
    }
}
