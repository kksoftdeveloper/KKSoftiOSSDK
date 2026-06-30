//
//  PurchasedSuccess.swift
//  PaymentSDK
//
//  Created by X on 9/21/25.
//

import Foundation

public struct PurchasedSuccess: Codable, Hashable, Equatable {
    
    public let productName: String
    public let transactionId: String?
    
    public init(productName: String, transactionId: String?) {
        self.productName = productName
        self.transactionId = transactionId
    }
}
