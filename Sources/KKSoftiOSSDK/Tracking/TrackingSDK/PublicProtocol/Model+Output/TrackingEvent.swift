//
//  TrackingEvent.swift
//  TrackingSDK
//
//  Created on 11/4/25.
//

import Foundation

/// Predefined tracking events for common use cases
public enum TrackingEvent: String {
    // User Events
    case userLogin = "user_login"
    case userLogout = "user_logout"
    case userSignup = "user_signup"
    case userProfileUpdate = "user_profile_update"
    
    // Purchase Events
    case purchaseInitiated = "purchase_initiated"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case purchaseCancelled = "purchase_cancelled"
    
    // Game Events
    case levelStart = "level_start"
    case levelComplete = "level_complete"
    case levelFailed = "level_failed"
    case achievementUnlocked = "achievement_unlocked"
    
    // App Events
    case appOpen = "app_open"
    case appClose = "app_close"
    case screenView = "screen_view"

    // AuthSDK / PaymentSDK canonical events
    case loginFormViewed = "login_form_viewed"
    case registration = "registration"
    case loginSuccess = "login_success"
    case loginFailure = "login_failure"
    case iapStart = "iap_start"
    case purchasePending = "purchase_pending"
    case purchaseSuccess = "purchase_success"
    case retentionD1 = "retention_d1"
    
    // Ingame Event
    case playGame = "play_game"
    case tutorialCompletedS1 = "tutorial_completed_s1"
    case level = "lev_"
    case vipLevel = "vip_lev_"
    case onlineTime = "online_"
    
    /// Get the event name as a string
    public var eventName: String {
        return self.rawValue
    }
}

/// Extension to provide convenience methods for tracking events
public extension TrackingManager {
    /// Track a predefined event
    /// - Parameters:
    ///   - event: Predefined tracking event
    ///   - parameters: Optional additional parameters
    ///   - overrides: Optional per-provider override rules
    func trackEvent(_ event: TrackingEvent, parameters: [String: Any]? = nil, overrides: TrackingEventOverrides? = nil) {
        trackEvent(event.eventName, parameters: parameters, overrides: overrides)
    }
}
