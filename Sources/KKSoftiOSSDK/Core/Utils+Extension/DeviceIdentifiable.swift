//
//  DeviceIdentifiable.swift
//  AuthSDK
//

import Foundation

protocol DeviceIdentifiable {
    var deviceID: String { get }
    
    var deviceSecretKey: String { get }
}

extension DeviceIdentifiable {
    var deviceID: String {
        do {
            return try SensitiveDataManager.shared.getDeviceID()
        } catch {
            fatalError("Unable to retrieve Device ID: \(error)")
        }
    }
    
    var deviceSecretKey: String {
        return Environment.deviceSecretKey
    }
}
