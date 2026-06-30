//
//  DefaultTrackingManager.swift
//  TrackingSDK
//
//  Created on 11/4/25.
//

import Foundation
import UIKit
import AdjustSdk

/// Default implementation of TrackingManager
/// Manages multiple tracking providers and routes events to all enabled providers
public final class DefaultTrackingManager: TrackingManager {
    
    // MARK: - Properties
    
    private var trackingProviders: [TrackingProvider] = []
    private var crashlyticsProvider: CrashlyticsProvider?
    
    private var isInitialized = false
    
    // MARK: - Initialization
    
    private init(builder: Builder) {
        self.trackingProviders = builder.trackingProviders
        self.crashlyticsProvider = builder.crashlyticsProvider
    }
    
    // MARK: - TrackingManager
    
    public func initialize() {
        guard !isInitialized else {
            print("[DefaultTrackingManager] Already initialized")
            return
        }
        
        // Initialize crashlytics if provided
        crashlyticsProvider?.initialize()
        
        isInitialized = true
        print("[DefaultTrackingManager] Initialized with \(trackingProviders.count) tracking providers")
    }
    
    public func trackEvent(_ eventName: String, parameters: [String: Any]?, overrides: TrackingEventOverrides?) {
//        guard isInitialized else {
//            print("[DefaultTrackingManager] Not initialized. Call initialize() first.")
//            return
//        }
        if !isInitialized {
            initialize()
        }
        // Track event across all providers
        for provider in trackingProviders {
            let override = overrides?[provider.kind]
            let resolvedName = override?.resolvedEventName(defaultName: eventName) ?? eventName
            let resolvedParams = override?.resolvedParameters(base: parameters) ?? parameters
            print("[DefaultTrackingManager] provider: \(type(of: provider)) -> \(resolvedName)")
            provider.trackEvent(resolvedName, parameters: resolvedParams)
        }
    }
    
    public func trackPurchase(productID: String, price: Double, currency: String, parameters: [String: Any]?) {
        guard isInitialized else {
            print("[DefaultTrackingManager] Not initialized. Call initialize() first.")
            return
        }
        
        // Track purchase across all providers
        for provider in trackingProviders {
            provider.trackPurchase(productID: productID, price: price, currency: currency, parameters: parameters)
        }
    }
    
    public func setUserProperties(_ properties: [String: Any]) {
        guard isInitialized else {
            print("[DefaultTrackingManager] Not initialized. Call initialize() first.")
            return
        }
        
        // Set user properties across all providers
        for provider in trackingProviders {
            provider.setUserProperties(properties)
        }
    }
    
    public func setUserID(_ userID: String) {
        guard isInitialized else {
            print("[DefaultTrackingManager] Not initialized. Call initialize() first.")
            return
        }
        
        // Set user ID across all providers
        for provider in trackingProviders {
            provider.setUserID(userID)
        }
        
        // Also set for crashlytics
        crashlyticsProvider?.setUserID(userID)
    }
    
    public func log(_ message: String) {
        crashlyticsProvider?.log(message)
    }
    
    public func recordError(_ error: Error) {
        crashlyticsProvider?.recordError(error)
    }
    
    public func recordException(name: String, reason: String, userInfo: [String: Any]?) {
        crashlyticsProvider?.recordException(name: name, reason: reason, userInfo: userInfo)
    }
    
    public func getIDFV() -> String? {
        // Try to get IDFV from AppFlyersProvider if available
        for provider in trackingProviders {
            if let appFlyersProvider = provider as? AppFlyersProvider {
                return appFlyersProvider.getIDFV()
            }
        }
        
        // Fallback: Get IDFV directly from UIDevice
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    /// Get Adjust ID (ADID) asynchronously
    /// - Parameter completion: Callback with Adjust ID or nil if not available
    public func getAdjustId(completion: @escaping (String?) -> Void) {
        print("[DefaultTrackingManager] Looking for Adjust provider among \(trackingProviders.count) providers")
        for provider in trackingProviders {
            print("[DefaultTrackingManager] Checking provider: \(type(of: provider))")
            if let adjustProvider = provider as? AdjustTrackingProvider {
                print("[DefaultTrackingManager] ✅ Found AdjustTrackingProvider, requesting Ad ID...")
                adjustProvider.getAdjustId(completion: completion)
                return
            }
        }
        // If no Adjust provider found, return nil
        print("[DefaultTrackingManager] ⚠️ No AdjustTrackingProvider found in tracking providers")
        completion(nil)
    }
    
    /// Get Adjust ID synchronously (may return nil if not yet available)
    /// - Returns: Adjust ID or nil if not available
    public func getAdjustIdSync() -> String? {
        for provider in trackingProviders {
            if let adjustProvider = provider as? AdjustTrackingProvider {
                return adjustProvider.getAdjustIdSync()
            }
        }
        return nil
    }
    
    public func getMobileCarrier() -> String? {
        return CarrierInfoProvider.currentCarrierName()
    }
    
    public func trackScreen(_ screenName: String, parameters: [String: Any]?, overrides: TrackingEventOverrides?) {
        // Auto-initialize if not already initialized
        if !isInitialized {
            initialize()
        }
        
        // Build screen tracking parameters with screen name included
        var screenParams: [String: Any] = parameters ?? [:]
        screenParams["screen_name"] = screenName
        
        // Track as a screen view event across all providers
        // Use the screen name as the event name, which allows providers to handle it appropriately
        for provider in trackingProviders {
            let override = overrides?[provider.kind]
            let resolvedName = override?.resolvedEventName(defaultName: screenName) ?? screenName
            let resolvedParams = override?.resolvedParameters(base: screenParams) ?? screenParams
            print("[DefaultTrackingManager] Tracking screen: \(resolvedName) with provider: \(type(of: provider))")
            provider.trackEvent(resolvedName, parameters: resolvedParams)
        }
    }
    
    // MARK: - Builder
    
    public final class Builder {
        var trackingProviders: [TrackingProvider] = []
        var crashlyticsProvider: CrashlyticsProvider?
        
        public init() {}
        
        /// Add a tracking provider (e.g., AppFlyers, Firebase Analytics)
        public func addTrackingProvider(_ provider: TrackingProvider) -> Builder {
            trackingProviders.append(provider)
            return self
        }
        
        /// Set crashlytics provider (e.g., Firebase Crashlytics)
        public func setCrashlyticsProvider(_ provider: CrashlyticsProvider) -> Builder {
            self.crashlyticsProvider = provider
            return self
        }
        
        /// Build the TrackingManager instance
        public func build() -> DefaultTrackingManager {
            return DefaultTrackingManager(builder: self)
        }
    }
}

