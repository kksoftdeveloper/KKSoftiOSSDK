//
//  TrackingManager.swift
//  TrackingSDK
//
//  Created on 11/4/25.
//

import Foundation

/// Main protocol for tracking management
/// Provides a unified interface for all tracking operations
public protocol TrackingManager {
    /// Initialize tracking with providers
    func initialize()
    
    /// Track a custom event across all enabled providers.
    /// - Parameters:
    ///   - eventName: Canonical event name.
    ///   - parameters: Optional event parameters.
    ///   - overrides: Optional per-provider overrides for event names or parameters.
    func trackEvent(_ eventName: String, parameters: [String: Any]?, overrides: TrackingEventOverrides?)
    
    /// Track a purchase event
    /// - Parameters:
    ///   - productID: Product identifier
    ///   - price: Price of the product
    ///   - currency: Currency code
    ///   - parameters: Optional additional parameters
    func trackPurchase(productID: String, price: Double, currency: String, parameters: [String: Any]?)
    
    /// Set user properties across all providers
    /// - Parameter properties: Dictionary of user properties
    func setUserProperties(_ properties: [String: Any])
    
    /// Set user ID across all providers
    /// - Parameter userID: User identifier
    func setUserID(_ userID: String)
    
    /// Log a message to crashlytics (if enabled)
    /// - Parameter message: Message to log
    func log(_ message: String)
    
    /// Record an error to crashlytics (if enabled)
    /// - Parameter error: Error to record
    func recordError(_ error: Error)
    
    /// Record a custom exception to crashlytics (if enabled)
    /// - Parameters:
    ///   - name: Exception name
    ///   - reason: Exception reason
    ///   - userInfo: Optional user info
    func recordException(name: String, reason: String, userInfo: [String: Any]?)
    
    /// Get IDFV (Identifier for Vendor) for testing purposes
    /// - Returns: IDFV string or nil if not available
    func getIDFV() -> String?
    
    /// Get the current mobile carrier name for attribution parameters
    /// - Returns: Carrier name string or nil if not available
    func getMobileCarrier() -> String?
    
    /// Get Adjust ID (ADID) asynchronously
    /// - Parameter completion: Callback with Adjust ID or nil if not available
    func getAdjustId(completion: @escaping (String?) -> Void)
    
    /// Track a screen view event across all enabled providers.
    /// This is a specialized event for tracking when users view specific screens in the app.
    /// - Parameters:
    ///   - screenName: Name of the screen being viewed (e.g., "Logout-Screen", "Login-Screen")
    ///   - parameters: Optional screen-specific parameters (e.g., screen_id, user_type, etc.)
    ///   - overrides: Optional per-provider overrides for event names or parameters
    func trackScreen(_ screenName: String, parameters: [String: Any]?, overrides: TrackingEventOverrides?)
}

/// Extension to provide convenience methods
public extension TrackingManager {
    /// Convenience overload that omits overrides.
    func trackEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        trackEvent(eventName, parameters: parameters, overrides: nil)
    }
    
    /// Log a custom event (alias for trackEvent)
    func logEvent(_ eventName: String, parameters: [String: Any]? = nil, overrides: TrackingEventOverrides? = nil) {
        trackEvent(eventName, parameters: parameters, overrides: overrides)
    }
    
    /// Convenience overload for trackScreen that omits overrides.
    /// - Parameters:
    ///   - screenName: Name of the screen being viewed
    ///   - parameters: Optional screen-specific parameters
    func trackScreen(_ screenName: String, parameters: [String: Any]? = nil) {
        trackScreen(screenName, parameters: parameters, overrides: nil)
    }
}

