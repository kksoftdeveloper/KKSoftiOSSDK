//
//  CrashlyticsProvider.swift
//  TrackingSDK
//
//  Created on 11/4/25.
//

import Foundation

/// Protocol for crash reporting providers (Firebase Crashlytics, etc.)
/// This allows for easy extension with new crash reporting services
public protocol CrashlyticsProvider {
    /// Initialize the crashlytics provider
    func initialize()
    
    /// Log a custom message
    /// - Parameter message: Message to log
    func log(_ message: String)
    
    /// Set a custom key-value pair
    /// - Parameters:
    ///   - value: Value to set
    ///   - forKey: Key for the value
    func setCustomValue(_ value: Any, forKey key: String)
    
    /// Set user identifier
    /// - Parameter userID: User identifier
    func setUserID(_ userID: String)
    
    /// Record a non-fatal error
    /// - Parameter error: Error to record
    func recordError(_ error: Error)
    
    /// Record a custom exception
    /// - Parameters:
    ///   - name: Exception name
    ///   - reason: Exception reason
    ///   - userInfo: Optional user info dictionary
    func recordException(name: String, reason: String, userInfo: [String: Any]?)
}

