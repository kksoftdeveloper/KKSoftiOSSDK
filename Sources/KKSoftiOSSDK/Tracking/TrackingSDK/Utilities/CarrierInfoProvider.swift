//
//  CarrierInfoProvider.swift
//  TrackingSDK
//
//  Created on 11/10/25.
//

import Foundation
import CoreTelephony

enum CarrierInfoProvider {
    
    /// Returns the first non-empty carrier name reported by the device.
    /// Handles dual-SIM and legacy single-SIM scenarios.
    static func currentCarrierName() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        
        if #available(iOS 12.0, *) {
            if let providers = networkInfo.serviceSubscriberCellularProviders?.values {
                let names = providers
                    .compactMap { cleanedCarrierName(from: $0) }
                    .filter { !$0.isEmpty }
                if let name = names.first {
                    return name
                }
            }
        }
        
        if let fallbackCarrier = networkInfo.subscriberCellularProvider,
           let name = cleanedCarrierName(from: fallbackCarrier),
           !name.isEmpty {
            return name
        }
        
        return nil
    }
    
    private static func cleanedCarrierName(from carrier: CTCarrier) -> String? {
        guard let rawName = carrier.carrierName else {
            return nil
        }
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

