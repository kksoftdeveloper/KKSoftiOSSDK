//
//  TransactionModel.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

struct TransactionModel {
    let id: String
    let amount: Double
    let currency: String
    let status: TransactionStatus
}

extension TransactionModel {
    
    func toOutput() -> TransactionOutput {
        return TransactionOutput(
            id: id,
            amount: amount,
            currency: currency,
            status: status.rawValue
        )
    }
}
