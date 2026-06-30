//
//  TrackingError.swift
//  TrackingSDK
//
//  Created on 11/4/25.
//

import Foundation

/// Errors that can occur in TrackingSDK
public enum TrackingError: Error, LocalizedError {
    case notInitialized
    case providerNotFound
    case invalidConfiguration
    case trackingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "TrackingSDK has not been initialized. Call initialize() first."
        case .providerNotFound:
            return "The requested tracking provider was not found."
        case .invalidConfiguration:
            return "Invalid configuration provided for tracking provider."
        case .trackingFailed(let reason):
            return "Tracking failed: \(reason)"
        }
    }
}

