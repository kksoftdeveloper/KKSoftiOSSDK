//
//  TransactionModel.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

struct PurchaseVerificationModel {
    let transactionCode: String
    let point: Int
}

extension PurchaseVerificationModel {
    func toOutput() -> PurchaseVerificationOutput {
        return PurchaseVerificationOutput(transactionCode: transactionCode, point: point)
    }
}
