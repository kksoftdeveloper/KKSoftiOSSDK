//
//  DeviceInfoKeychainStorage.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

final class DeviceInfoKeychainStorage: DeviceInfoStorage {
    
    private let service = "com.dar.payment.data.storage.deviceinfo"
    private let deviceId = "DeviceId"
    private let osVersion = "OSVersion"
    
    func saveDeviceId(_ deviceId: String) throws {
        debugPrint("device-info saving \(deviceId)")
        // Store under a stable account key so we can read it back later
        try KeychainHelper.shared.save(deviceId.data(using: .utf8)!, service: service, account: self.deviceId)
        debugPrint("device-info saved \(deviceId)")
    }
    
    func getDeviceId() throws -> String? {
        debugPrint("device-info getting")
        guard let data = try KeychainHelper.shared.load(service: service, account: deviceId) else {
            debugPrint("device-info getted: deviceId = nil")
            return nil
        }
        debugPrint("device-info getted \(String(describing: String(data: data, encoding: .utf8)))")
        return String(data: data, encoding: .utf8)
    }
    
    func saveOSVersion(_ osVersion: String) throws {
        try KeychainHelper.shared.save(osVersion.data(using: .utf8)!, service: service, account: self.osVersion)
        
    }
    
    func getOSVersion() throws -> String? {
        guard let data = try KeychainHelper.shared.load(service: service, account: osVersion) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    func clear() throws {
        try KeychainHelper.shared.delete(service: service, account: deviceId)
    }
}
