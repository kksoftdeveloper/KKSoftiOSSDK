//
//  MetaTrackingProvider.swift
//  TrackingSDK
//

import Foundation
import FacebookCore

/// Meta App Events implementation of TrackingProvider.
public final class MetaTrackingProvider: TrackingProvider {
    
    public let kind: TrackingProviderKind = .meta
    
    private var isInitialized = false
    private var userProperties: [String: Any] = [:]
    
    public init(appID: String, clientToken: String) {
        initialize(appID: appID, devKey: clientToken)
    }
    
    // MARK: - TrackingProvider
    
    public func initialize(appID: String, devKey: String) {
        guard !isInitialized else {
            print("[MetaTrackingProvider] Already initialized")
            return
        }
        
        guard !appID.isEmpty, !devKey.isEmpty else {
            print("[MetaTrackingProvider] Invalid Meta configuration")
            return
        }
        
        Settings.shared.appID = appID
        Settings.shared.clientToken = devKey
        isInitialized = true
        print("[MetaTrackingProvider] Initialized with appID: \(appID)")
    }
    
    public func trackEvent(_ eventName: String, parameters: [String: Any]?) {
        guard isInitialized else {
            print("[MetaTrackingProvider] Not initialized. Call initialize() first.")
            return
        }
        
        AppEvents.shared.logEvent(
            AppEvents.Name(eventName),
            parameters: mergedParameters(parameters)
        )
        print("[MetaTrackingProvider] Tracked event: \(eventName)")
    }
    
    public func trackPurchase(productID: String, price: Double, currency: String, parameters: [String: Any]?) {
        guard isInitialized else {
            print("[MetaTrackingProvider] Not initialized. Call initialize() first.")
            return
        }
        
        var purchaseParameters = mergedParameters(parameters)
        purchaseParameters[AppEvents.ParameterName("product_id")] = productID
        AppEvents.shared.logPurchase(
            amount: price,
            currency: currency,
            parameters: purchaseParameters
        )
        print("[MetaTrackingProvider] Tracked purchase: \(productID), price: \(price) \(currency)")
    }
    
    public func setUserProperties(_ properties: [String: Any]) {
        userProperties.merge(sanitizeParameters(properties)) { _, newValue in newValue }
        print("[MetaTrackingProvider] Stored user properties for future events: \(properties.keys.sorted())")
    }
    
    public func setUserID(_ userID: String) {
        guard isInitialized else {
            print("[MetaTrackingProvider] Not initialized. Call initialize() first.")
            return
        }
        
        AppEvents.shared.userID = userID
        print("[MetaTrackingProvider] Set user ID")
    }
    
    // MARK: - Helpers
    
    private func mergedParameters(_ parameters: [String: Any]?) -> [AppEvents.ParameterName: Any] {
        var merged = userProperties
        merged.merge(sanitizeParameters(parameters ?? [:])) { _, newValue in newValue }
        return merged.reduce(into: [:]) { result, pair in
            result[AppEvents.ParameterName(pair.key)] = pair.value
        }
    }
    
    private func sanitizeParameters(_ parameters: [String: Any]) -> [String: Any] {
        parameters.mapValues { value in
            switch value {
            case let value as String:
                return value
            case let value as NSNumber:
                return value
            case let value as Bool:
                return NSNumber(value: value)
            case let value as Int:
                return NSNumber(value: value)
            case let value as Double:
                return NSNumber(value: value)
            case let value as Float:
                return NSNumber(value: value)
            default:
                return String(describing: value)
            }
        }
    }
}
