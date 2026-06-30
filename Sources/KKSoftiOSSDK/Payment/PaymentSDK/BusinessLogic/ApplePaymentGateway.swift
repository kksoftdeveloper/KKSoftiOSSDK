import Foundation
import Combine
import StoreKit

final class ApplePaymentGateway: PaymentGateway, IAPAnalytics {
    
    private var paymentAPIClient: PaymentAPIClient
    private var signature: Signature
    
    init(paymentAPIClient: PaymentAPIClient, signature: Signature = SHA256Signature()) {
        self.paymentAPIClient = paymentAPIClient
        self.signature = signature
    }

    func fetchProducts(productIDs: [String]) -> AnyPublisher<[Product], PaymentError> {
        Future { promise in
            Task {
                do {
                    let products = try await Product.products(for: productIDs)
                    debugPrint("fetch products with apple payment gate way: \(products)")
                    
                    promise(.success(products))
                } catch {
                    promise(.failure(.purchaseFailed(reason: error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func purchase(product: Product) -> AnyPublisher<AppleVerifiedTranskModel, PaymentError> {
        Future<AppleVerifiedTranskModel, PaymentError> { promise in
            Task {
                do {
                    let result = try await product.purchase()
                    let properties: [String: Any] = [
                        "productId": product.id
                    ]
                    switch result {
                    case .success(let verification):
                        switch verification {
                            
                        case .verified(let transaction):
                            await transaction.finish()
                            let appleVerifiedTransk = AppleVerifiedTranskModel(appleTransk: transaction, purchasedToken: verification.jwsRepresentation)
                            promise(.success(appleVerifiedTransk))
                            debugPrint("[PackageListViewModel] verified: \(verification.jwsRepresentation)")
                           
                            
                            BaseAnalytics.track(event: self.applePurchase, properties: ["verified": properties.toMixpanelType()])
                        case .unverified(_, let error):
                            debugPrint("[PackageListViewModel] unverified: \(verification.jwsRepresentation)")
                            BaseAnalytics.track(event: self.applePurchase, properties: ["unverified": properties.toMixpanelType()])
                            promise(.failure(.purchaseFailed(reason: error.localizedDescription)))
                        }
                    case .userCancelled:
                        debugPrint("[PackageListViewModel] userCancelled")
                        BaseAnalytics.track(event: self.applePurchase, properties: ["userCanceled": properties.toMixpanelType()])
                        promise(.failure(.purchaseCancelled()))
                    default:
                        BaseAnalytics.track(event: self.applePurchase, properties: ["failed": properties.toMixpanelType()])
                        debugPrint("[PackageListViewModel] default")
                        promise(.failure(.purchaseFailed(reason: "Unknown purchase result")))
                    }
                } catch {
                    debugPrint("[PackageListViewModel] error: \(error.localizedDescription)")
                    let errorData = ["message": error.localizedDescription]
                    BaseAnalytics.track(event: self.applePurchase, properties: ["error": errorData.toDictionary().toMixpanelType()])
                    promise(.failure(.purchaseFailed(reason: error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func validateGamePackage(gamePackage: GamePackageParams) -> AnyPublisher<GamePackageStatusOutput, PaymentError> {
        var gamePackage = gamePackage
        guard let signature = try? self.signature.sign(sku: gamePackage.sku, price: gamePackage.price, serverId: "\(gamePackage.serverId)") else {
            return Fail(error: PaymentError.sdkNotInitialized()).eraseToAnyPublisher()
        }
        gamePackage.sign = signature
        BaseAnalytics.track(event: self.validateGamePackages, properties: [self.request : gamePackage.toDictionary().toMixpanelType()])
        return paymentAPIClient.validateGamePackage(body: gamePackage.toDictionary())
            .map { response in
                return response.data.toModel().toOutput()
            }
            .mapError { error in
                return error as? PaymentError ?? PaymentError.productNotFound()
            }
            .eraseToAnyPublisher()
    }
    
    func verifyGamePackagePurchase(gamePackagePurchase: PurchaseVerificationParams) -> AnyPublisher<PurchaseVerificationOutput, PaymentError> {
        var gamePackagePurchase = gamePackagePurchase
        let timeStamp = Int(Date().timeIntervalSince1970)
        guard let signature = try? self.signature.sign(
            sku: gamePackagePurchase.sku,
            transactionId: gamePackagePurchase.transactionId,
            serverId: gamePackagePurchase.serverId,
            purchaseToken: gamePackagePurchase.signedTransactionInfo
        ) else {
            return Fail(error: PaymentError.sdkNotInitialized()).eraseToAnyPublisher()
        }
        gamePackagePurchase.sign = signature
        if let dict = gamePackagePurchase.toDictionaryOptional() {
            var req = dict.toMixpanelType()
            if let signedInfo = req["signedTransactionInfo"] as? String {
                req["signedTransactionInfo"] = signedInfo.truncatedMiddle()
            }
            BaseAnalytics.track(event: self.verifyGamePackages, properties: [self.request: req])
        }
        return paymentAPIClient.verifyGamePackagePurchase(body: gamePackagePurchase.toDictionary())
            .map { response in
                return response.data.toModel().toOutput()
            }
            .mapError { error in
                return error as? PaymentError ?? PaymentError.purchaseFailed(reason: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    func getGamePackages(gamePackage: GetGamePackageParams) -> AnyPublisher<[GamePackageStatusOutput], PaymentError> {
        BaseAnalytics.track(event: self.getGamePackages, properties: [self.request : gamePackage.toDictionary().toMixpanelType()])
        return paymentAPIClient.getGamePackages(body: gamePackage.toDictionary())
            .map { response in
                return response.data.content.map { $0.toModel().toOutput() }
            }
            .mapError { error in
                return error as? PaymentError ?? PaymentError.productNotFound()
            }
            .eraseToAnyPublisher()
    }
}

struct GamePackageParams: Encodable {
    let sku: String
    let price: Int
    let gameId: Int
    let serverId: Int
    let platform: String
    let appVersion: String
    let sdkVersion: String
    var sign: String
    
    private enum CodingKeys: String, CodingKey {
        case sku, price, gameId, serverId, platform, appVersion, sdkVersion, sign
    }
}

/**
 {
     "sku": "package_1000",
     "transactionId": "1684278",
     "signedTransactionInfo": "eyJhbGciOi........",
     "gameId": 1,
     "serverId": 1,
     "platform": "ios",
     "appVersion":"1.0",
     "sdkVersion":"2.0",
     "sign": "sdhjsjdshjdhjs" // sku|transactionId|gameId|serverId|platform|appVersion|sdkVersion|secretKey
 }
 */

struct PurchaseVerificationParams: Encodable {
    let sku: String
    let transactionId: String
    let signedTransactionInfo: String
    let gameId: Int
    let serverId: String
    let platform: String
    let appVersion: String
    let sdkVersion: String
    var sign: String

    private enum CodingKeys: String, CodingKey {
        case sku, gameId, serverId, platform, appVersion, sdkVersion, sign
        case signedTransactionInfo = "signedTransactionInfo"
        case transactionId = "purchaseToken"
        
    }
}

struct GetGamePackageParams: Encodable {
    let gameId: Int
    let serverId: Int
    let platform: String
    let size: Int
    let page: Int
    
    private enum CodingKeys: String, CodingKey {
        case gameId, serverId, platform, size, page
    }
}
