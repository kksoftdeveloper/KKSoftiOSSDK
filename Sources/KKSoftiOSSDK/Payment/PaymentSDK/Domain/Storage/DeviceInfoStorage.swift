//
//  DeviceInfoStorage.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

protocol DeviceInfoStorage {
    func saveDeviceId(_ deviceId: String) throws
    func getDeviceId() throws -> String?

    func saveOSVersion(_ osVersion: String) throws
    func getOSVersion() throws -> String?
    
    func clear() throws
}
