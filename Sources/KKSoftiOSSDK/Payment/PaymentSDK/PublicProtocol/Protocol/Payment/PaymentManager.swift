//
//  PaymentManagerType.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation
import Combine
import StoreKit

public protocol PaymentManager {
    var accessToken: String { get }
    var refreshToken: String { get }
    
    var deviceId: String { get }
    var osVersion: String { get }
    
    var packageName: String { get }
    var appVersion: String { get }
    
    var gameId: Int { get }
    var gameServerId: String { get }
    var gameUUID: String { get }
    
    var phoneNumber: String { get }
    var guestUser: Bool { get }
    
    func initSDK() -> AnyPublisher<DatalessOutput, Error>
    
    func fetchGamePackages(gameId: Int, serverId: Int, size: Int, page: Int) -> AnyPublisher<[GamePackageStatusOutput], PaymentError>
    func fetchProducts(productIDs: [String]) -> AnyPublisher<[Product], PaymentError>
    func purchase(product: Product) -> AnyPublisher<AppleVerifiedTranskModel, PaymentError>
    func validateGamePackage(gamePackage: GamePackageInput) -> AnyPublisher<GamePackageStatusOutput, PaymentError>
    func verifyGamePackagePurchase(gamePackagePurchase: GamePackagePurchaseInput) -> AnyPublisher<PurchaseVerificationOutput, PaymentError>
    
    func deactiveAccount() -> AnyPublisher<DatalessOutput, PaymentError>
}
