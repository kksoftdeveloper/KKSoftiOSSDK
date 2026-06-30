//
//  TrackingProvider.swift
//  TrackingSDK
//
//  Created on 11/4/25.
//

import Foundation

/// Identifiers for built-in tracking providers.
/// Use `.custom` for any providers supplied outside the SDK.
public enum TrackingProviderKind: Hashable {
    case appsFlyer
    case firebaseAnalytics
    case adjust
    case tiktok
    case meta
    case custom(String)
    
    public var identifier: String {
        switch self {
        case .appsFlyer:
            return "appsFlyer"
        case .firebaseAnalytics:
            return "firebaseAnalytics"
        case .adjust:
            return "adjust"
        case .tiktok:
            return "tiktok"
        case .meta:
            return "meta"
        case .custom(let value):
            return value
        }
    }
}

/// Protocol for tracking providers (AppFlyers, Firebase Analytics, etc.)
/// This allows for easy extension with new tracking services
public protocol TrackingProvider {
    /// Identifier used for provider-specific overrides.
    var kind: TrackingProviderKind { get }
    
    /// Initialize the tracking provider
    /// - Parameters:
    ///   - appID: Application ID for the tracking service
    ///   - devKey: Developer key for the tracking service
    func initialize(appID: String, devKey: String)
    
    /// Track a custom event
    /// - Parameters:
    ///   - eventName: Name of the event to track
    ///   - parameters: Optional dictionary of event parameters
    func trackEvent(_ eventName: String, parameters: [String: Any]?)
    
    /// Track a purchase event
    /// - Parameters:
    ///   - productID: Product identifier
    ///   - price: Price of the product
    ///   - currency: Currency code (e.g., "USD")
    ///   - parameters: Optional additional parameters
    func trackPurchase(productID: String, price: Double, currency: String, parameters: [String: Any]?)
    
    /// Set user properties
    /// - Parameter properties: Dictionary of user properties
    func setUserProperties(_ properties: [String: Any])
    
    /// Set user ID
    /// - Parameter userID: User identifier
    func setUserID(_ userID: String)
    
    /// Log a custom event (alias for trackEvent for convenience)
    /// - Parameters:
    ///   - eventName: Name of the event
    ///   - parameters: Optional event parameters
    func logEvent(_ eventName: String, parameters: [String: Any]?)
}

/// Extension to provide default implementation for logEvent
public extension TrackingProvider {
    func logEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        trackEvent(eventName, parameters: parameters)
    }
}

