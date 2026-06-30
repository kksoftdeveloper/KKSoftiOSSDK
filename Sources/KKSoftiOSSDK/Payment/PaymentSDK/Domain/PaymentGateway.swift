//
//  PaymentGateway.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation
import Combine
import StoreKit

protocol PaymentGateway {
    func getGamePackages(gamePackage: GetGamePackageParams) -> AnyPublisher<[GamePackageStatusOutput], PaymentError>
    func fetchProducts(productIDs: [String]) -> AnyPublisher<[Product], PaymentError>
    func purchase(product: Product) -> AnyPublisher<AppleVerifiedTranskModel, PaymentError>
    func validateGamePackage(gamePackage: GamePackageParams) -> AnyPublisher<GamePackageStatusOutput, PaymentError>
    func verifyGamePackagePurchase(gamePackagePurchase: PurchaseVerificationParams) -> AnyPublisher<PurchaseVerificationOutput, PaymentError> 
}

