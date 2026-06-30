//
//  FirebaseAnalyticsProvider.swift
//  TrackingSDK
//
//  Created on 11/4/25.
//
//  NOTE: This is a placeholder for future Firebase Analytics implementation
//  To use this, add Firebase Analytics dependency to Package.swift:
//  .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
//

import Foundation

import FirebaseCore
import FirebaseAnalytics

/// Firebase Analytics implementation of TrackingProvider
/// This is a placeholder that can be implemented when Firebase is added
public final class FirebaseAnalyticsProvider: TrackingProvider {
    
    public let kind: TrackingProviderKind = .firebaseAnalytics
    
    private var isInitialized = false
    
    public init(appID: String, devKey: String) {
        initialize(appID: appID, devKey: devKey)
    }
    
    // MARK: - TrackingProvider
    
    public func initialize(appID: String, devKey: String) {
        guard !isInitialized else {
            print("[FirebaseAnalyticsProvider] Already initialized")
            return
        }
        
#if DEBUG
        // Enable Firebase Analytics debug mode so events stream to DebugView without extra Xcode flags
        setenv("FIRAnalyticsDebugEnabled", "1", 1)
        setenv("FIRDebugEnabled", "1", 1)
        print("[FirebaseAnalyticsProvider] Debug mode enabled (-FIRDebugEnabled)")
#endif
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Analytics.setAnalyticsCollectionEnabled(true)
        
        isInitialized = true
        print("[FirebaseAnalyticsProvider] Initialized with appID: \(appID)")
    }
    
    public func trackEvent(_ eventName: String, parameters: [String: Any]?) {
        guard isInitialized else {
            print("[FirebaseAnalyticsProvider] Not initialized. Call initialize() first.")
            return
        }
        
        let sanitizedName = sanitizeEventName(eventName)
        let cleaned = sanitizeParameters(parameters)
        Analytics.logEvent(sanitizedName, parameters: cleaned)
        print("[FirebaseAnalyticsProvider] Tracked event: \(eventName) with parameters: \(parameters ?? [:])")
    }
    
    public func trackPurchase(productID: String, price: Double, currency: String, parameters: [String: Any]?) {
        guard isInitialized else {
            print("[FirebaseAnalyticsProvider] Not initialized. Call initialize() first.")
            return
        }
        
        var purchaseParams = sanitizeParameters(parameters)
        purchaseParams[AnalyticsParameterItemID] = productID
        purchaseParams[AnalyticsParameterPrice] = price
        purchaseParams[AnalyticsParameterCurrency] = currency
        Analytics.logEvent(AnalyticsEventPurchase, parameters: purchaseParams)
        
        print("[FirebaseAnalyticsProvider] Tracked purchase: \(productID), price: \(price) \(currency)")
    }
    
    public func setUserProperties(_ properties: [String: Any]) {
        guard isInitialized else {
            print("[FirebaseAnalyticsProvider] Not initialized. Call initialize() first.")
            return
        }
        
        properties.forEach { key, value in
            Analytics.setUserProperty(String(describing: value), forName: sanitizeParameterKey(key))
        }
        print("[FirebaseAnalyticsProvider] Set user properties: \(properties)")
    }
    
    public func setUserID(_ userID: String) {
        guard isInitialized else {
            print("[FirebaseAnalyticsProvider] Not initialized. Call initialize() first.")
            return
        }
        
        Analytics.setUserID(userID)
        print("[FirebaseAnalyticsProvider] Set user ID: \(userID)")
    }

    // MARK: - Helpers

    private func sanitizeEventName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        let filtered = name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        var sanitized = String(filtered)
        if sanitized.count > 40 {
            sanitized = String(sanitized.prefix(40))
        }
        if sanitized.first?.isNumber == true {
            sanitized = "e_\(sanitized)"
        }
        return sanitized
    }

    private func sanitizeParameterKey(_ key: String) -> String {
        var sanitized = key.replacingOccurrences(of: "[^A-Za-z0-9_]", with: "_", options: .regularExpression)
        if sanitized.count > 40 {
            sanitized = String(sanitized.prefix(40))
        }
        if sanitized.isEmpty {
            sanitized = "param"
        }
        return sanitized
    }

    private func sanitizeParameters(_ parameters: [String: Any]?) -> [String: Any] {
        guard let parameters else { return [:] }
        var cleaned: [String: Any] = [:]
        parameters.forEach { key, value in
            let sanitizedKey = sanitizeParameterKey(key)
            switch value {
            case let v as String:
                cleaned[sanitizedKey] = v
            case let v as NSNumber:
                cleaned[sanitizedKey] = v
            case let v as Bool:
                cleaned[sanitizedKey] = NSNumber(value: v)
            case let v as Int:
                cleaned[sanitizedKey] = NSNumber(value: v)
            case let v as Double:
                cleaned[sanitizedKey] = NSNumber(value: v)
            case let v as Float:
                cleaned[sanitizedKey] = NSNumber(value: v)
            default:
                cleaned[sanitizedKey] = String(describing: value)
            }
        }
        return cleaned
    }
}

