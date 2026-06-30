//
//  PaymentTracking.swift
//  PaymentSDK
//

import Foundation
import StoreKit

public enum PaymentTrackingConfigurator {
    private static var storedManager: TrackingManager?
    private static var hasInitialized = false
    
    @MainActor
    public static func configure(with manager: TrackingManager?) {
        storedManager = manager
        guard let manager else { return }
        if !hasInitialized {
            manager.initialize()
            hasInitialized = true
        }
        PaymentTracking.manager = manager
    }
    
    static var currentManager: TrackingManager? {
        storedManager
    }
}

enum PaymentTracking {
    fileprivate static var manager: TrackingManager?
    
    static func logIAPStart(gameUUID: String?, characterId: String?, serverId: Int?, serverName: String?) {
        var params: [String: Any] = [:]
        set(gameUUID, for: "user_id", in: &params)
        set(characterId, for: "character_id", in: &params)
        set(serverId, for: "server_id", in: &params)
        set(serverName, for: "server_name", in: &params)
        params["mobile_carrier"] = manager?.getMobileCarrier() ?? ""
        manager?.log("[PaymentTracking] Start IAP uid=\(gameUUID ?? "unknown") character=\(characterId ?? "n/a") server=\(serverId ?? 0)")
        manager?.trackEvent(
            .iapStart,
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_start_iap",
                firebaseName: "fb_start_iap",
                adjustToken: "o12zna",
                appsFlyerMutator: {
                    renameKey(&$0, from: "user_id", to: "af_uid")
                    renameKey(&$0, from: "character_id", to: "af_character_id")
                    renameKey(&$0, from: "server_id", to: "af_server_id")
                    renameKey(&$0, from: "server_name", to: "af_server_name")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "mobile_carrier")
                    removeKey(&$0, key: "server_id")
                    removeKey(&$0, key: "server_name")
                },
                adjustMutator: {
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                    renameKey(&$0, from: "character_id", to: "adj_character_id")
                    renameKey(&$0, from: "server_id", to: "adj_server_id")
                    renameKey(&$0, from: "server_name", to: "adj_server_name")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                }
            )
        )
        print("[PaymentTracking] Tracked iap_start with params: \(params)")
    }
    
    static func logIAPSuccess(product: Product, orderId: String, gameUUID: String?, characterId: String?, serverId: Int?, serverName: String?) {
        var params = productParameters(for: product)
        set(gameUUID, for: "user_id", in: &params)
        set(characterId, for: "character", in: &params)
        set(serverId, for: "server_id", in: &params)
        set(serverName, for: "server_name", in: &params)
        params["mobile_carrier"] = manager?.getMobileCarrier() ?? ""
        params["order_id"] = orderId
        manager?.log("[PaymentTracking] IAP success sku=\(product.id) orderId=\(orderId)")
        guard manager != nil else {
            print("[PaymentTracking] manager is nil")
            return
        }
        manager?.trackEvent(
            .purchaseSuccess,
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_pay_success",
                firebaseName: "in_app_purchase",
                adjustToken: "z6cmoc",
                appsFlyerMutator: {
                    renameKey(&$0, from: "user_id", to: "af_uid")
                    renameKey(&$0, from: "character", to: "af_character_id")
                    renameKey(&$0, from: "server_id", to: "af_server_id")
                    renameKey(&$0, from: "server_name", to: "af_server_name")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                    renameKey(&$0, from: "package_name", to: "af_package_id")
                    renameKey(&$0, from: "currency", to: "af_currency")
                    renameKey(&$0, from: "price", to: "af_revenue")
                    renameKey(&$0, from: "order_id", to: "af_order_id")
                    removeKey(&$0, key: "package_id")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "mobile_carrier")
                    removeKey(&$0, key: "server_id")
                    removeKey(&$0, key: "server_name")
                    renameKey(&$0, from: "order_id", to: "transaction_id")
                    renameKey(&$0, from: "package_name", to: "item_name")
                    removeKey(&$0, key: "package_id")
                    renameKey(&$0, from: "price", to: "value")
                },
                adjustMutator: {
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                    renameKey(&$0, from: "character", to: "adj_character_id")
                    renameKey(&$0, from: "server_id", to: "adj_server_id")
                    renameKey(&$0, from: "server_name", to: "adj_server_name")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                    renameKey(&$0, from: "package_name", to: "adj_package_id")
                    renameKey(&$0, from: "currency", to: "adj_currency")
                    renameKey(&$0, from: "price", to: "adj_revenue")
                    renameKey(&$0, from: "order_id", to: "adj_order_id")
                    removeKey(&$0, key: "package_id")
                }
            )
        )
        print("[PaymentTracking] Tracked pay_success with params: \(params)")
        print(String(describing: PaymentTrackingConfigurator.currentManager))
    }
    
    static func logIAPFailure(product: Product, reason: String, error: PaymentError?, gameUUID: String?, characterId: String?, serverId: Int?, serverName: String?) {
        var params = productParameters(for: product)
        set(gameUUID, for: "user_id", in: &params)
        set(characterId, for: "character", in: &params)
        set(serverId, for: "server_id", in: &params)
        set(serverName, for: "server_name", in: &params)
        params["mobile_carrier"] = manager?.getMobileCarrier() ?? ""
        params["order_status"] = reason
        
        manager?.log("[PaymentTracking] IAP failure sku=\(product.id) reason=\(reason)")
        guard let manager else {
            print("[PaymentTracking] manager is nil")
            return
        }
        manager.trackEvent(
            .purchasePending,
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_pay_notyet_success",
                firebaseName: "fb_pay_notyet_success",
                adjustToken: "31d9dl",
                appsFlyerMutator: {
                    renameKey(&$0, from: "order_status", to: "af_order_status")
                    renameKey(&$0, from: "user_id", to: "af_uid")
                    renameKey(&$0, from: "character", to: "af_character_id")
                    renameKey(&$0, from: "server_id", to: "af_server_id")
                    renameKey(&$0, from: "server_name", to: "af_server_name")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                    renameKey(&$0, from: "package_name", to: "af_package_id")
                    renameKey(&$0, from: "currency", to: "af_currency")
                    removeKey(&$0, key: "package_id")
                    removeKey(&$0, key: "price")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "mobile_carrier")
                    removeKey(&$0, key: "server_id")
                    removeKey(&$0, key: "server_name")
                    renameKey(&$0, from: "package_name", to: "item_name")
                    removeKey(&$0, key: "package_id")
                    removeKey(&$0, key: "price")
                    removeKey(&$0, key: "order_status")
                },
                adjustMutator: {
                    renameKey(&$0, from: "order_status", to: "adj_order_status")
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                    renameKey(&$0, from: "character", to: "adj_character_id")
                    renameKey(&$0, from: "server_id", to: "adj_server_id")
                    renameKey(&$0, from: "server_name", to: "adj_server_name")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                    renameKey(&$0, from: "package_name", to: "adj_package_id")
                    renameKey(&$0, from: "currency", to: "adj_currency")
                    removeKey(&$0, key: "package_id")
                    removeKey(&$0, key: "price")
                }
            )
        )
        if let error {
            manager.recordError(error)
        } else {
            let wrappedError = NSError(
                domain: "PaymentTracking",
                code: PaymentErrorCode.PurchaseFailed.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: reason,
                    "sku": product.id
                ]
            )
            manager.recordError(wrappedError)
        }
        print("[PaymentTracking] Tracked pay_notyet_success with params: \(params)")
    }
    
    private static func productParameters(for product: Product) -> [String: Any] {
        return [
            "package_id": product.id,
            "currency": "VND",
            "price": product.displayPrice,
            "package_name": product.displayName
        ]
    }
    
    private static func providerOverrides(
        appsFlyerName: String,
        firebaseName: String,
        adjustToken: String? = nil,
        appsFlyerMutator: ((inout [String: Any]) -> Void)? = nil,
        firebaseMutator: ((inout [String: Any]) -> Void)? = nil,
        adjustMutator: ((inout [String: Any]) -> Void)? = nil
    ) -> TrackingEventOverrides {
        var overrides: TrackingEventOverrides = [:]
        overrides[.appsFlyer] = ProviderEventOverride(
            eventName: appsFlyerName,
            parameterMutator: appsFlyerMutator
        )
        overrides[.firebaseAnalytics] = ProviderEventOverride(
            eventName: firebaseName,
            parameterMutator: firebaseMutator
        )
        if let adjustToken = adjustToken {
            overrides[.adjust] = ProviderEventOverride(
                eventName: adjustToken,
                parameterMutator: adjustMutator
            )
        }
        return overrides
    }
    
    private static func renameKey(_ params: inout [String: Any], from oldKey: String, to newKey: String) {
        guard let value = params.removeValue(forKey: oldKey) else { return }
        params[newKey] = value
    }
    
    private static func set(_ value: Any?, for key: String, in params: inout [String: Any]) {
        guard let value else { return }
        params[key] = value
    }
    
    private static func removeKey(_ params: inout [String: Any], key: String) {
        params.removeValue(forKey: key)
    }
}

