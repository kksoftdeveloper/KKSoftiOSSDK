//
//  IAPAnalytics.swift
//  AuthSDK
//
//  Created by Kai on 9/20/25.
//

import Foundation

//fun PurchaseStatus.toMixpanelEvent(): String {
//  return when (this) {
//    is PurchaseStatus.Success -> "purchaseSuccess"
//    PurchaseStatus.UserCancelled -> "purchaseUserCancelled"
//    PurchaseStatus.BillingUnavailable -> "purchaseBillingUnavailable"
//    PurchaseStatus.ProductUnavailable -> "purchaseProductUnavailable"
//    PurchaseStatus.ProductUnavailableInGameServer -> "purchaseProductUnavailableInGameServer"
//    PurchaseStatus.Error -> "purchaseError"
//    PurchaseStatus.Idle -> "purchaseIdle"
//  }
//}


protocol IAPAnalytics {
    var IAPInit: String { get }
    
    var purchasedSuccess: String { get }
    var purchasedUserCancel: String { get }
    var purchasedFail: String { get }
    var purchasedError: String { get }
    var purchasedInvalidSKU: String { get }
    
    var request: String { get }
    var success: String { get }
    var failure: String { get }
    
    var appleGamePackages: String { get }
    var applePurchase: String { get }
    var getGamePackages: String { get }
    var validateGamePackages: String { get }
    var verifyGamePackages: String { get }
}

extension IAPAnalytics {
    var IAPInit: String { "IAPInit" }
    
    var applePurchase: String { "applePurchase" }
    
    var purchasedSuccess: String { "purchasedSuccess" }
    
    var purchasedUserCancel: String { "purchasedUserCancel" }
    
    var purchasedFail: String { "purchasedFailure" }
    
    var purchasedError: String { "purchasedError" }
    
    var purchasedInvalidSKU: String { "purchasedInvalidSKU" }
    
    var appleGamePackages: String { "appleGamePackages" }
    
    var getGamePackages: String { "getGamePackages" }
    
    var validateGamePackages: String { "validateGamePackages" }
    
    var verifyGamePackages: String { "verifyGamePackages" }
    
    var request: String { "request" }
    
    var success: String { "success" }
    
    var failure: String { "failure" }
}
