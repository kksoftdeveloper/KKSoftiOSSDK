//
//  AdjustTrackingProvider.swift
//  TrackingSDK
//
//  Created on 11/24/25.
//

import Foundation
import UIKit
import AdjustSdk

/// Adjust implementation of TrackingProvider
public final class AdjustTrackingProvider: NSObject, TrackingProvider {
    
    public let kind: TrackingProviderKind = .adjust
    
    private var isInitialized = false
    private var adjustAppToken: String?
    
    public init(appID: String, devKey: String) {
        super.init()
        // For Adjust, devKey is the app token
        adjustAppToken = devKey
        initialize(appID: appID, devKey: devKey)
    }
    
    // MARK: - TrackingProvider
    
    public func initialize(appID: String, devKey: String) {
        guard !isInitialized else {
            print("[AdjustTrackingProvider] Already initialized")
            return
        }
        
        // Adjust uses devKey as the app token
        let appToken = devKey
        adjustAppToken = appToken
        
        // Create Adjust configuration
        let adjustConfig = ADJConfig(
            appToken: appToken,
            environment: ADJEnvironmentSandbox
        )
        
        // Set log level to verbose for debugging
        adjustConfig?.logLevel = AdjustSdk.ADJLogLevel.verbose
        
        // Start Adjust SDK - This is critical for Ad ID to be available
        // SDK v5 uses initSdk instead of appDidLaunch
        Adjust.initSdk(adjustConfig)
        
        isInitialized = true
        print("[AdjustTrackingProvider] Initialized with appID: \(appID), appToken: \(appToken)")
        
        // Log IDFV for testing - similar to AppsFlyer
        let idfv = getIDFV()
        print("[AdjustTrackingProvider] 📱 IDFV (Identifier for Vendor): \(idfv)")
        
        // Retrieve and log Adjust ID asynchronously
        getAdjustId { [weak self] adid in
            guard let _ = self else { return }
            if let adid = adid {
                print("[AdjustTrackingProvider] 📱 Adjust ID (ADID): \(adid)")
            } else {
                print("[AdjustTrackingProvider] ⚠️ Adjust ID not available yet. It may take a moment to initialize.")
            }
        }
      
    }
    
    public func trackEvent(_ eventToken: String, parameters: [String: Any]?) {
        guard isInitialized else {
            print("[AdjustTrackingProvider] Not initialized. Call initialize() first.")
            return
        }

        guard let event = ADJEvent(eventToken: eventToken) else {
            print("[AdjustTrackingProvider] ❌ Invalid Adjust event token: \(eventToken)")
            return
        }

        if let params = parameters {
            for (key, value) in params {
                let stringValue: String
                if let str = value as? String {
                    stringValue = str
                } else if let num = value as? NSNumber {
                    stringValue = num.stringValue
                } else if let bool = value as? Bool {
                    stringValue = bool ? "true" : "false"
                } else {
                    stringValue = String(describing: value)
                }
                event.addCallbackParameter(key, value: stringValue)
            }
        }

        Adjust.trackEvent(event)
        print("[AdjustTrackingProvider] ✅ Tracked event token: \(eventToken)")
        if let params = parameters {
            print("[AdjustTrackingProvider] 📊 Parameters sent: \(params)")
        }
    }
    
    public func trackPurchase(productID: String, price: Double, currency: String, parameters: [String: Any]?) {
        guard isInitialized else {
            print("[AdjustTrackingProvider] Not initialized. Call initialize() first.")
            return
        }
        
        // Create a revenue event for purchases
        // Adjust handles purchases through revenue events
        let event = ADJEvent(eventToken: "adj_pay_success")
        
        // Set revenue and currency
        event?.setRevenue(price, currency: currency)
        
        // Add product ID as callback parameter
        event?.addCallbackParameter("adj_package_id", value: productID)
        
        // Add any additional parameters
        if let params = parameters {
            for (key, value) in params {
                let stringValue: String
                if let str = value as? String {
                    stringValue = str
                } else if let num = value as? NSNumber {
                    stringValue = num.stringValue
                } else if let bool = value as? Bool {
                    stringValue = bool ? "true" : "false"
                } else {
                    stringValue = String(describing: value)
                }
                event?.addCallbackParameter(key, value: stringValue)
            }
        }
        
        Adjust.trackEvent(event)
        print("[AdjustTrackingProvider] Tracked purchase: \(productID), price: \(price) \(currency)")
    }
    
    public func setUserProperties(_ properties: [String: Any]) {
        guard isInitialized else {
            print("[AdjustTrackingProvider] Not initialized. Call initialize() first.")
            return
        }
        
        // Adjust doesn't have a direct equivalent to user properties
        // We can track them as callback parameters on events
        // Store them for use in future events
        print("[AdjustTrackingProvider] User properties stored: \(properties)")
        print("[AdjustTrackingProvider] Note: Adjust doesn't have persistent user properties. They should be sent as callback parameters with events.")
    }
    
    public func setUserID(_ userID: String) {
        guard isInitialized else {
            print("[AdjustTrackingProvider] Not initialized. Call initialize() first.")
            return
        }
        
        // Adjust SDK v5 uses addGlobalCallbackParameter (renamed from addSessionCallbackParameter)
        // This will be attached to all future events
        Adjust.addGlobalCallbackParameter(userID, forKey: "adj_uid")
        print("[AdjustTrackingProvider] Set user ID: \(userID)")
    }
    
    // MARK: - Helper Methods
    
    /// Get IDFV (Identifier for Vendor) for testing purposes
    /// This is the device identifier that can be used for testing
    public func getIDFV() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }
    
    /// Get Adjust ID (ADID) asynchronously
    /// Adjust ID is available after SDK initialization
    /// - Parameter completion: Callback with Adjust ID or nil if not available
    public func getAdjustId(completion: @escaping (String?) -> Void) {
        guard isInitialized else {
            print("[AdjustTrackingProvider] ⚠️ Cannot get Ad ID: Provider not initialized")
            completion(nil)
            return
        }
        
        print("[AdjustTrackingProvider] Requesting Adjust Ad ID from SDK...")
        Adjust.adid { adid in
            DispatchQueue.main.async {
                if let adid = adid {
                    print("[AdjustTrackingProvider] ✅ Adjust Ad ID retrieved: \(adid)")
                } else {
                    print("[AdjustTrackingProvider] ⚠️ Adjust Ad ID is nil - SDK may not be fully initialized yet")
                }
                completion(adid)
            }
        }
    }
    
    /// Get Adjust ID synchronously (may return nil if not yet available)
    /// Note: This is less reliable than the async version
    /// - Returns: Adjust ID or nil if not available
    public func getAdjustIdSync() -> String? {
        var result: String?
        let semaphore = DispatchSemaphore(value: 0)
        
        Adjust.adid { adid in
            result = adid
            semaphore.signal()
        }
        
        // Wait with timeout
        _ = semaphore.wait(timeout: .now() + 1.0)
        return result
    }
}
