//
//  TransactionModel.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

struct GamePackageStatusModel {
    let sku: String
    let status: String
    let price: Int
    let point: Int
    let alias: String?
    let description: String?
}

extension GamePackageStatusModel {
    func toOutput() -> GamePackageStatusOutput {
        return GamePackageStatusOutput(sku: sku, status: status, price: price, point: point, alias: alias, description: description)
    }
}
