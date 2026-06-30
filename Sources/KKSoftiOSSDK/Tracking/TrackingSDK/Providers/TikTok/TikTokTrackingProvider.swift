//
//  TikTokTrackingProvider.swift
//  TrackingSDK
//

import Foundation
import TikTokBusinessSDK

/// TikTok App Events SDK implementation of TrackingProvider.
public final class TikTokTrackingProvider: TrackingProvider {
    
    public let kind: TrackingProviderKind = .tiktok
    
    private let tiktokAppID: String
    private var isInitialized = false
    private var pendingActions: [() -> Void] = []
    private var userProperties: [String: Any] = [:]
    
    public init(accessToken: String, appID: String, tiktokAppID: String) {
        self.tiktokAppID = tiktokAppID
        initialize(appID: appID, devKey: accessToken)
    }
    
    // MARK: - TrackingProvider
    
    public func initialize(appID: String, devKey: String) {
        guard !isInitialized else {
            print("[TikTokTrackingProvider] Already initialized")
            return
        }
        
        guard let config = TikTokConfig(
            accessToken: devKey,
            appId: appID,
            tiktokAppId: tiktokAppID
        ) else {
            print("[TikTokTrackingProvider] Invalid TikTok configuration")
            return
        }
        
#if DEBUG
        config.debugModeEnabled = true
#endif
        // Purchases are sent explicitly through trackPurchase to avoid duplicate events.
        config.disablePaymentTracking()
        
        TikTokBusiness.initializeSdk(config) { [weak self] success, error in
            guard let self else { return }
            guard success else {
                self.pendingActions.removeAll()
                print("[TikTokTrackingProvider] Initialization failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.isInitialized = true
            let actions = self.pendingActions
            self.pendingActions.removeAll()
            actions.forEach { $0() }
            print("[TikTokTrackingProvider] Initialized with appID: \(appID), tiktokAppID: \(self.tiktokAppID)")
        }
    }
    
    public func trackEvent(_ eventName: String, parameters: [String: Any]?) {
        performWhenInitialized { [weak self] in
            guard let self else { return }
            
            let event = TikTokBaseEvent(
                eventName: eventName,
                properties: self.mergedParameters(parameters),
                eventId: nil
            )
            TikTokBusiness.trackTTEvent(event)
            print("[TikTokTrackingProvider] Tracked event: \(eventName)")
        }
    }
    
    public func trackPurchase(productID: String, price: Double, currency: String, parameters: [String: Any]?) {
        performWhenInitialized { [weak self] in
            guard let self else { return }
            
            let event = TikTokPurchaseEvent(eventId: UUID().uuidString)
            event.setCurrency(TTCurrency(rawValue: currency))
            event.setValue(String(price))
            event.setContentId(productID)
            
            for (key, value) in self.mergedParameters(parameters) {
                event.addProperty(withKey: key, value: value)
            }
            
            TikTokBusiness.trackTTEvent(event)
            print("[TikTokTrackingProvider] Tracked purchase: \(productID), price: \(price) \(currency)")
        }
    }
    
    public func setUserProperties(_ properties: [String: Any]) {
        userProperties.merge(sanitizeParameters(properties)) { _, newValue in newValue }
        print("[TikTokTrackingProvider] Stored user properties for future events: \(properties.keys.sorted())")
    }
    
    public func setUserID(_ userID: String) {
        performWhenInitialized {
            TikTokBusiness.identify(
                withExternalID: userID,
                externalUserName: nil,
                phoneNumber: nil,
                email: nil
            )
            print("[TikTokTrackingProvider] Set external user ID")
        }
    }
    
    // MARK: - Helpers
    
    private func performWhenInitialized(_ action: @escaping () -> Void) {
        guard isInitialized else {
            pendingActions.append(action)
            print("[TikTokTrackingProvider] Queued action until initialization completes")
            return
        }
        
        action()
    }
    
    private func mergedParameters(_ parameters: [String: Any]?) -> [String: Any] {
        var merged = userProperties
        merged.merge(sanitizeParameters(parameters ?? [:])) { _, newValue in newValue }
        return merged
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
