import Foundation
import Combine
import SwiftUI
import StoreKit

struct PackageItemModel: Identifiable {
    let product: Product?
    let package: GamePackageStatusOutput
    
    var id: String { package.sku }
    var serverPrice: Int { package.price }
    var points: Int { package.point }
    var displayPoints: Int {
        if package.point >= 10_000 && package.point % 100 == 0 {
            return package.point / 100
        }
        return package.point
    }
    var alias: String? { package.alias }
    var description: String? { package.description }
    var displayPrice: String {
        if let product {
            return product.displayPrice
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: package.price)) ?? "\(package.price)"
    }
    var isActive: Bool { package.status.uppercased() == "ACTIVE" }
    var isPurchasable: Bool { isActive && product != nil }
}

@MainActor
public class PackageListViewModel: ObservableObject, IAPAnalytics {
    
    @Published var isLoading = false
    @Published var products: [PackageItemModel] = []
    @Published var paymentPopUp: PaymentPopUp?
    
    let paymentManager: DefaultPaymentManager?
    var cancellables = Set<AnyCancellable>()
    
    @Published var page: Int = 0
    @Published var hasMorePages: Bool = true
    private let pageSize: Int = 10
    private var isLoadingPage = false
    
    private var gameId: Int = 1
    private var serverId: Int = 0
    private var pendingTransactionId: String?
    
    public init(paymentManager: DefaultPaymentManager?) {
        self.paymentManager = paymentManager
        self.gameId = self.paymentManager?.gameId ?? 1
        self.serverId = self.paymentManager?.serverId ?? 0
    }
    
    func loadGamePackages(reset: Bool = false) {
        guard let paymentManager else { return }
        
        guard !isLoadingPage, hasMorePages || reset else { return }

        isLoadingPage = true
        
        // Show loading indicator on initial load (reset) or when products list is empty
        if reset || products.isEmpty {
            isLoading = true
        }

        if reset {
            page = 0
            hasMorePages = true
            products = []
        }
        
        paymentManager.fetchGamePackages(gameId: self.gameId, serverId: self.serverId, size: pageSize, page: page)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoadingPage = false
                
                if case .failure(let error) = completion {
                    debugPrint("❌ Failed to fetch packages: \(error.message)")
                    // Only hide loading if this was initial load
                    if reset || self.products.isEmpty {
                        self.isLoading = false
                    }
                }
            } receiveValue: { [weak self] packages in
                guard let self else { return }

                let skus = packages.map { $0.sku }
                
                if packages.isEmpty || packages.count < pageSize {
                    self.hasMorePages = false
                }
                print(skus)
                
                if packages.isEmpty && self.products.isEmpty {
//                    let productIds = ["com.i.kk.27knb","com.i.kk.135knb","com.i.kk.270knb","com.i.kk.810knb","com.i.kk.540knb","com.i.kk.2700knb","com.i.kk.1080knb"]
                    loadProducts(packages: packages, append: false, isInitialLoad: reset || self.products.isEmpty)
                } else {
                    self.page += 1
                    self.loadProducts(packages: packages, append: !reset, isInitialLoad: reset || self.products.isEmpty)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadProducts(packages: [GamePackageStatusOutput], append: Bool = false, isInitialLoad: Bool = false) {
        let skus = packages.map { $0.sku }
        debugPrint("fetch products: \(skus)")
        isLoadingPage = true
        paymentManager?.fetchProducts(productIDs: skus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                if case .failure(let error) = completion {
                    debugPrint("[PackageListViewModel] Failed to fetch products: \(error.message)")
                    self.updateProducts(storeProducts: [], packages: packages, append: append)
                }
                self.isLoadingPage = false
                // Hide loading indicator when initial load completes
                if isInitialLoad {
                    self.isLoading = false
                }
            } receiveValue: { [weak self] newProducts in
                debugPrint("[PackageListViewModel] fetch products with new products: \(newProducts)")
                guard let self else { return }

                self.updateProducts(storeProducts: newProducts, packages: packages, append: append)
                
                self.isLoadingPage = false
                // Hide loading indicator when initial load completes
                if isInitialLoad {
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
        
    private func updateProducts(storeProducts: [Product], packages: [GamePackageStatusOutput], append: Bool) {
        let productsByID = Dictionary(uniqueKeysWithValues: storeProducts.map { ($0.id, $0) })
        let mappedItems = packages.map { package in
            PackageItemModel(product: productsByID[package.sku], package: package)
        }

        if append {
            let existingIDs = Set(products.map(\.id))
            let uniqueItems = mappedItems.filter { !existingIDs.contains($0.id) }
            products.append(contentsOf: uniqueItems)
        } else {
            products = mappedItems
        }

        products.sort {
            priceValue(for: $0) < priceValue(for: $1)
        }
    }

    func purchaseProduct(_ item: PackageItemModel) {
        //For Debug
//        handleApplePurchaseProduct(product: product)
//        return
        
        guard item.isActive, let product = item.product else {
            debugPrint("[PackageListViewModel] Package is not purchasable for SKU: \(item.id), status: \(item.package.status)")
            return
        }
        isLoading = true
        let price = priceValue(for: item)
        debugPrint("[PackageListViewModel] IAP: product-id: \(product.id), price: \(price)")
        paymentManager?
            .validateGamePackage(gamePackage: GamePackageInput(sku: product.id, price: price))
            .catch({ error in
                return Fail(error: error).eraseToAnyPublisher()
            })
            .flatMap { [weak self] gamePackageStatus -> AnyPublisher<AppleVerifiedTranskModel, PaymentError> in
                guard let self = self, let paymentManager = paymentManager else {
                    return Fail(error: PaymentError.unknownError()).eraseToAnyPublisher()
                }
                debugPrint("[PackageListViewModel] IAP: game-package-status: \(gamePackageStatus.status)")
                if gamePackageStatus.status != "ACTIVE" {
                    return Fail(error: PaymentError.inactivedSKU()).eraseToAnyPublisher()
                }
                return paymentManager.purchase(product: product)
            }
            .flatMap { [weak self] appleVerifiedTranskModel -> AnyPublisher<PurchaseVerificationOutput, PaymentError> in
                debugPrint("[PackageListViewModel] IAP: transaction-purchasedToken \(appleVerifiedTranskModel.purchasedToken)")
                debugPrint("[PackageListViewModel] IAP: transactionId \(String(appleVerifiedTranskModel.appleTransk.id))")
                guard let self = self, let paymentManager = paymentManager else {
                    return Fail(error: PaymentError.unknownError()).eraseToAnyPublisher()
                }
                self.pendingTransactionId = String(appleVerifiedTranskModel.appleTransk.id)
                return paymentManager.verifyGamePackagePurchase(
                    gamePackagePurchase: GamePackagePurchaseInput(
                        sku: appleVerifiedTranskModel.appleTransk.productID,
                        transactionId: String(appleVerifiedTranskModel.appleTransk.id),
                        signedTransactionInfo: appleVerifiedTranskModel.purchasedToken
                    )
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false

                switch completion {
                case .finished:
                    self.pendingTransactionId = nil
                case .failure(let error):
                    self.pendingTransactionId = nil
                    debugPrint("[PackageListViewModel] Purchase flow failed: \(error)")
                    switch error.code {
                    case .InvalidSKU:
//                        PaymentTracking.logIAPFailure(product: product, reason: "invalid_sku", error: error)
                        BaseAnalytics.track(event: self.purchasedInvalidSKU, properties: [self.failure: "Invalid SKU: \(error), \(product.id)"])
                        let notificationCenter = NotificationCenter.default
                        notificationCenter.post(
                            name: NSNotification.Name(NotificationKeys.IAP_INVALID_SKU),
                            object: PurchasedFailure(),
                            userInfo: [
                                "sku": product.id,
                                "price_value": priceValue,
                                "display_price": product.displayPrice,
                                "error_code": error.code.rawValue,
                                "error_message": error.message
                            ]
                        )
                        self.paymentPopUp = PaymentPopUp(
                            title: LocalizedStringKey.sdkAsset("payment_fail").toString(),
                            description: LocalizedStringKey.sdkAsset("invalid_sku").toString(),
                            buttonTitle: LocalizedStringKey.sdkAsset("try_again").toString(),
                            product: product,
                            orderId: nil,
                            kind: .failure(reason: "invalid_sku", error: error)
                        )
                    case .InactivedSKU:
//                        PaymentTracking.logIAPFailure(product: product, reason: "inactivated_sku", error: error)
                        BaseAnalytics.track(event: self.purchasedInvalidSKU, properties: [self.failure: "Inactived SKU: \(error), \(product.id)"])
                        let notificationCenter = NotificationCenter.default
                        notificationCenter.post(
                            name: NSNotification.Name(NotificationKeys.IAP_INVALID_SKU),
                            object: PurchasedFailure(),
                            userInfo: [
                                "sku": product.id,
                                "price_value": priceValue,
                                "display_price": product.displayPrice,
                                "error_code": error.code.rawValue,
                                "error_message": error.message
                            ]
                        )
                        self.paymentPopUp = PaymentPopUp(
                            title: LocalizedStringKey.sdkAsset("payment_fail").toString(),
                            description: LocalizedStringKey.sdkAsset("invalid_sku").toString(),
                            buttonTitle: LocalizedStringKey.sdkAsset("try_again").toString(),
                            product: product,
                            orderId: nil,
                            kind: .failure(reason: "inactivated_sku", error: error)
                        )
                    case .PurchaseCancelled:
//                        PaymentTracking.logIAPFailure(product: product, reason: "user_cancel", error: error)
                        BaseAnalytics.track(event: self.purchasedUserCancel, properties: [self.failure: "Usercancel: \(error)"])
                        let notificationCenter = NotificationCenter.default
                        notificationCenter.post(
                            name: NSNotification.Name(NotificationKeys.IAP_USER_CANCEL),
                            object: PurchasedUserCancel(),
                            userInfo: [
                                "sku": product.id,
                                "price_value": priceValue,
                                "display_price": product.displayPrice,
                                "error_code": error.code.rawValue,
                                "error_message": error.message
                            ]
                        )
                        break
                    default:
                        BaseAnalytics.track(event: self.purchasedFail, properties: [self.failure: "Fail: \(error)"])
                        let notificationCenter = NotificationCenter.default
                        notificationCenter.post(
                            name: NSNotification.Name(NotificationKeys.IAP_FAIL),
                            object: PurchasedFailure(),
                            userInfo: [
                                "sku": product.id,
                                "price_value": priceValue,
                                "display_price": product.displayPrice,
                                "error_code": error.code.rawValue,
                                "error_message": error.message
                            ]
                        )
                        self.paymentPopUp = PaymentPopUp(
                            title: LocalizedStringKey.sdkAsset("payment_fail").toString(),
                            description:  LocalizedStringKey.sdkAsset("payment_fail_desc").toString(),
                            buttonTitle: LocalizedStringKey.sdkAsset("try_again").toString(),
                            product: product,
                            orderId: nil,
                            kind: .failure(reason: "failure", error: error)
                        )
                    }
                    
                }
                self.isLoading = false
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.isLoading = false
                let orderId = self.pendingTransactionId ?? ""
                let data = PurchasedSuccess(productName: product.displayName, transactionId: orderId.isEmpty ? nil : orderId)
                let notificationCenter = NotificationCenter.default
                notificationCenter.post(
                    name: NSNotification.Name(NotificationKeys.IAP_SUCCESS),
                    object: data,
                    userInfo: [
                        "sku": product.id,
                        "product_name": product.displayName,
                        "price_value": priceValue,
                        "display_price": product.displayPrice,
                        "transaction_id": orderId
                    ]
                )
                debugPrint("[PackageListViewModel] Purchase flow completed successfully.")
                self.paymentPopUp = PaymentPopUp(
                    title: LocalizedStringKey.sdkAsset("payment_success").toString().uppercased(),
                    description: String(format: LocalizedStringKey.sdkAsset("payment_success_desc").toString(), product.displayName),
                    buttonTitle: LocalizedStringKey.sdkAsset("close").toString(),
                    product: product,
                    orderId: orderId,
                    kind: .success(orderId: orderId.isEmpty ? nil : orderId)
                )
//                PaymentTracking.logIAPSuccess(product: product, orderId: orderId)
                BaseAnalytics.track(event: self.purchasedSuccess, properties: [self.success: product.displayName])
            }
            .store(in: &cancellables)
    }
    
    private func priceValue(for item: PackageItemModel) -> Int {
        item.serverPrice
    }
    
        
    func handleApplePurchaseProduct(product: Product) {
        let price = NSDecimalNumber(decimal: product.price).intValue
        debugPrint("[PackageListViewModel] IAP: product-id: \(product.id), price: \(price)")
        paymentManager?.purchase(product: product)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false

                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint("[PackageListViewModel] Purchase failed: \(error.message)")
                }
            } receiveValue: { [weak self] transaction in
                guard let _ = self else { return }
                debugPrint("[PackageListViewModel] Purchase successful: \(transaction.appleTransk.productID)")
                debugPrint("[PackageListViewModel] IAP: transactionId \(String(transaction.appleTransk.id))")
                
                print(transaction)
            }
            .store(in: &cancellables)
    }
}
