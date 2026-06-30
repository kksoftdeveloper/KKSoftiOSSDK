import Foundation
import StoreKit

enum AlertType: Identifiable {
    case onFail(String)
    case onSuccess(String)
    
    var id: String {
        switch self {
        case .onFail(let message):
            return message
        case .onSuccess(let message):
            return message
        }
    }
}

struct PaymentPopUp: Identifiable {
    enum Kind {
        case success(orderId: String?)
        case failure(reason: String, error: PaymentError?)
    }
    
    let id = UUID()
    let title: String
    let description: String
    let buttonTitle: String
    let product: Product?
    let orderId: String?
    let kind: Kind
}
