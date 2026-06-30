import Foundation

public struct GamePackagePurchaseInput: Codable, Equatable, Hashable  {
    let sku: String
    let transactionId: String
    let signedTransactionInfo: String
}
