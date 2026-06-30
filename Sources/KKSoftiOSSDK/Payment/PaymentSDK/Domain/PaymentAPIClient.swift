//
//  PaymentAPIClient.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation
import Combine

protocol PaymentAPIClient {
    func initSDK(body: InitSDKRequestBody) -> AnyPublisher<PaymentSDKInitResponse, Error>
    func validateGamePackage(body: [String : Any]?) -> AnyPublisher<GamePackageStatusResponse, Error>
    func verifyGamePackagePurchase(body: [String : Any]?) -> AnyPublisher<PurchaseVerificationResponse, Error>
    func getGamePackages(body: [String : Any]?) -> AnyPublisher<GamePackagesResponse, any Error>
    func deactiveAccount(header: [String: Any]) -> AnyPublisher<DatalessServerResponse, Error>
}
