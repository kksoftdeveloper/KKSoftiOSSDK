//
//  AppFlyersProvider.swift
//  TrackingSDK
//
//  Created on 11/4/25.
//

import Foundation
import UIKit
import AppsFlyerLib
import AppTrackingTransparency

/// AppFlyers implementation of TrackingProvider
public final class AppFlyersProvider: NSObject, TrackingProvider {
    
    public let kind: TrackingProviderKind = .appsFlyer
    
    private var isInitialized = false
    
    public init(appID: String, devKey: String) {
        super.init()
        initialize(appID: appID, devKey: devKey)
    }
    
    // MARK: - TrackingProvider
    
    public func initialize(appID: String, devKey: String) {
        guard !isInitialized else {
            print("[AppFlyersProvider] Already initialized")
            return
        }
        
        AppsFlyerLib.shared().appsFlyerDevKey = devKey
        AppsFlyerLib.shared().appleAppID = appID
        AppsFlyerLib.shared().isDebug = true // Enable debug mode to see events in real-time
        
        // Set delegate for deep linking and conversion tracking
        AppsFlyerLib.shared().delegate = self
        
        isInitialized = true
        print("[AppFlyersProvider] Initialized with appID: \(appID), devKey: \(devKey)")
        
        // Log IDFV for testing - this is needed to add device to AppsFlyer dashboard for testing
        let idfv = getIDFV()
        print("[AppFlyersProvider] 📱 IDFV (Identifier for Vendor): \(idfv)")
        print("[AppFlyersProvider] 💡 Copy this IDFV and add it to AppsFlyer dashboard for testing")
        
        // IMPORTANT: Start AppsFlyer SDK - this is required for tracking to work
        // Note: This should be called from the app delegate's didFinishLaunchingWithOptions
        // or after the app is fully initialized
        DispatchQueue.main.async {
            AppsFlyerLib.shared().start()
            print("[AppFlyersProvider] AppsFlyer SDK started")
            
            // Request ATT permission after app is fully loaded
            // Delay to ensure the app UI is ready before showing the permission dialog
            // This delay is important - the permission dialog must be shown from the main thread
            // and after the app's UI is fully presented
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("[AppFlyersProvider] ⏰ Requesting ATT permission now...")
                self.requestATTrackingPermission()
            }
        }
    }
    
    public func trackEvent(_ eventName: String, parameters: [String: Any]?) {
        guard isInitialized else {
            print("[AppFlyersProvider] Not initialized. Call initialize() first.")
            return
        }
        
        // Convert parameters to NSDictionary for AppsFlyer compatibility
        var eventParams: [String: Any] = parameters ?? [:]
        
        // Ensure all values are compatible with AppsFlyer (String, Number, Bool)
        // AppsFlyer doesn't support complex types in event parameters
        let cleanedParams = eventParams.compactMapValues { value -> Any? in
            // Convert to supported types
            if value is String || value is NSNumber || value is Bool {
                return value
            } else if let number = value as? Int {
                return NSNumber(value: number)
            } else if let double = value as? Double {
                return NSNumber(value: double)
            } else if let float = value as? Float {
                return NSNumber(value: float)
            } else {
                // Convert other types to string
                return String(describing: value)
            }
        }
        
        // Convert to NSDictionary for AppsFlyer
        let nsParams = cleanedParams as NSDictionary
        
        // AppFlyers uses logEvent for custom events
        // Note: Event parameters are sent to AppsFlyer but may not appear in main dashboard
        // They are available in Raw Data reports (CSV download) and via AppsFlyer API
        AppsFlyerLib.shared().logEvent(eventName, withValues: nsParams as! [AnyHashable : Any])
        
        print("[AppFlyersProvider] ✅ Tracked event: \(eventName)")
        print("[AppFlyersProvider] 📊 Parameters sent: \(cleanedParams)")
        print("[AppFlyersProvider] 💡 Parameters are sent to AppsFlyer successfully")
        print("[AppFlyersProvider] 💡 To view parameters in AppsFlyer dashboard:")
        print("[AppFlyersProvider]    1. Go to Dashboard > Raw Data Reports")
        print("[AppFlyersProvider]    2. Download CSV file for your app")
        print("[AppFlyersProvider]    3. Look for event_name = '\(eventName)' and check event_parameters column")
        print("[AppFlyersProvider]    4. Or use AppsFlyer API: https://hq1.appsflyer.com/api/export/app/{app_id}/in_app_events_report/v5")
    }
    
    public func trackPurchase(productID: String, price: Double, currency: String, parameters: [String: Any]?) {
        guard isInitialized else {
            print("[AppFlyersProvider] Not initialized. Call initialize() first.")
            return
        }
        
        var purchaseParams: [String: Any] = parameters ?? [:]
        purchaseParams["af_revenue"] = price
        purchaseParams["af_currency"] = currency
        purchaseParams["af_product_id"] = productID
        
        // Use AFEventPurchase for purchase tracking
        AppsFlyerLib.shared().logEvent(AFEventPurchase, withValues: purchaseParams)
        print("[AppFlyersProvider] Tracked purchase: \(productID), price: \(price) \(currency)")
    }
    
    public func setUserProperties(_ properties: [String: Any]) {
        guard isInitialized else {
            print("[AppFlyersProvider] Not initialized. Call initialize() first.")
            return
        }
        
        // AppFlyers uses customData property for user properties
        // Merge with existing customData if any
        var existingData = AppsFlyerLib.shared().customData ?? [:]
        for (key, value) in properties {
            existingData[key] = value
        }
        AppsFlyerLib.shared().customData = existingData
        print("[AppFlyersProvider] Set user properties: \(properties)")
    }
    
    public func setUserID(_ userID: String) {
        guard isInitialized else {
            print("[AppFlyersProvider] Not initialized. Call initialize() first.")
            return
        }
        
        // AppFlyers uses setCustomerUserID
        AppsFlyerLib.shared().customerUserID = userID
        print("[AppFlyersProvider] Set user ID: \(userID)")
    }
    
    // MARK: - Helper Methods
    
    /// Get IDFV (Identifier for Vendor) for testing purposes
    /// This is the device identifier that can be added to AppsFlyer dashboard for testing
    public func getIDFV() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }
    
    /// Request ATT (App Tracking Transparency) permission
    /// This allows AppsFlyer to access IDFA for better attribution
    /// Note: This will only show the dialog if status is .notDetermined
    /// If previously denied, user must change it in Settings > Privacy & Security > Tracking
    /// IMPORTANT: The app must appear in Settings > Privacy & Security > Tracking after the first request
    public func requestATTrackingPermission() {
        if #available(iOS 14, *) {
            // Ensure we're on the main thread
            guard Thread.isMainThread else {
                DispatchQueue.main.async {
                    self.requestATTrackingPermission()
                }
                return
            }
            
            // Check current authorization status
            let status = ATTrackingManager.trackingAuthorizationStatus
            
            // Map status to readable string
            let statusString: String
            switch status {
            case .notDetermined:
                statusString = "notDetermined (0)"
            case .restricted:
                statusString = "restricted (1)"
            case .denied:
                statusString = "denied (2)"
            case .authorized:
                statusString = "authorized (3)"
            @unknown default:
                statusString = "unknown (\(status.rawValue))"
            }
            
            print("[AppFlyersProvider] 📊 Current ATT status: \(statusString)")
            print("[AppFlyersProvider] 📱 Thread: \(Thread.isMainThread ? "Main" : "Background")")
            
            // Verify Info.plist has NSUserTrackingUsageDescription
            if let infoPlist = Bundle.main.infoDictionary,
               let trackingDescription = infoPlist["NSUserTrackingUsageDescription"] as? String {
                print("[AppFlyersProvider] ✅ Info.plist has NSUserTrackingUsageDescription: \"\(trackingDescription)\"")
            } else {
                print("[AppFlyersProvider] ⚠️ WARNING: Info.plist missing NSUserTrackingUsageDescription!")
                print("[AppFlyersProvider] 💡 Add this key to Info.plist for ATT to work")
            }
            
            switch status {
            case .notDetermined:
                // Request permission if not determined
                print("[AppFlyersProvider] 📱 Requesting ATT permission...")
                print("[AppFlyersProvider] 💡 User will see permission dialog now")
                print("[AppFlyersProvider] 💡 After user responds, app will appear in Settings > Privacy & Security > Tracking")
                
                ATTrackingManager.requestTrackingAuthorization { authorizationStatus in
                    DispatchQueue.main.async {
                        let resultString: String
                        switch authorizationStatus {
                        case .authorized:
                            resultString = "authorized (3)"
                        case .denied:
                            resultString = "denied (2)"
                        case .restricted:
                            resultString = "restricted (1)"
                        case .notDetermined:
                            resultString = "notDetermined (0)"
                        @unknown default:
                            resultString = "unknown (\(authorizationStatus.rawValue))"
                        }
                        
                        print("[AppFlyersProvider] 📊 User responded with status: \(resultString)")
                        
                        switch authorizationStatus {
                        case .authorized:
                            print("[AppFlyersProvider] ✅ ATT: Tracking authorized - IDFA available")
                            print("[AppFlyersProvider] ✅ App should now appear in Settings > Privacy & Security > Tracking")
                        case .denied:
                            print("[AppFlyersProvider] ❌ ATT: Tracking denied - IDFA not available")
                            print("[AppFlyersProvider] ✅ App should now appear in Settings > Privacy & Security > Tracking")
                            print("[AppFlyersProvider] 💡 To enable: Settings > Privacy & Security > Tracking > [App Name]")
                        case .restricted:
                            print("[AppFlyersProvider] ⚠️ ATT: Tracking restricted - IDFA not available")
                            print("[AppFlyersProvider] 💡 Tracking is restricted by device settings (e.g., Screen Time)")
                        case .notDetermined:
                            print("[AppFlyersProvider] ⚠️ ATT: Tracking not determined (unexpected)")
                        @unknown default:
                            print("[AppFlyersProvider] ⚠️ ATT: Unknown status")
                        }
                    }
                }
            case .authorized:
                print("[AppFlyersProvider] ✅ ATT: Already authorized - IDFA available")
                print("[AppFlyersProvider] ✅ App should appear in Settings > Privacy & Security > Tracking")
            case .denied:
                print("[AppFlyersProvider] ❌ ATT: Permission denied - IDFA not available")
                print("[AppFlyersProvider] ✅ App should appear in Settings > Privacy & Security > Tracking")
                print("[AppFlyersProvider] 💡 Permission was previously denied. To enable:")
                print("[AppFlyersProvider]    1. Go to Settings > Privacy & Security > Tracking")
                print("[AppFlyersProvider]    2. Find your app (com.kksoft.vn.ts3) and enable tracking")
                print("[AppFlyersProvider]    3. Restart the app")
                print("[AppFlyersProvider] 💡 If app doesn't appear in Settings, delete and reinstall the app")
            case .restricted:
                print("[AppFlyersProvider] ⚠️ ATT: Permission restricted - IDFA not available")
                print("[AppFlyersProvider] 💡 Tracking is restricted by device settings (e.g., Screen Time)")
            @unknown default:
                print("[AppFlyersProvider] ⚠️ ATT: Unknown status")
            }
        } else {
            print("[AppFlyersProvider] ⚠️ ATT: Not available on iOS < 14")
        }
    }
}

// MARK: - AppsFlyerLibDelegate (Optional - for deep linking)
extension AppFlyersProvider: AppsFlyerLibDelegate {
    public func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        print("[AppFlyersProvider] Conversion data: \(conversionInfo)")
    }
    
    public func onConversionDataFail(_ error: Error) {
        print("[AppFlyersProvider] Conversion data error: \(error)")
    }
    
    public func onAppOpenAttribution(_ attributionData: [AnyHashable : Any]) {
        print("[AppFlyersProvider] App open attribution: \(attributionData)")
    }
    
    public func onAppOpenAttributionFailure(_ error: Error) {
        print("[AppFlyersProvider] App open attribution error: \(error)")
    }
}

