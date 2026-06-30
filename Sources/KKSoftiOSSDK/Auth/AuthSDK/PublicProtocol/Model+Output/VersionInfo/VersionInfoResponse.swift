//
//  GameInfo.swift
//  AuthSDK
//

import Foundation

public struct VersionInfoResponse: Codable {
    
    public let forceUpdate: Bool
    public let minSdkVersion: String
    public let minAppVersion: String
    public let latestSdkVersion: String
    public let latestAppVersion: String
    
    private enum CodingKeys: String, CodingKey {
        case forceUpdate, minSdkVersion, minAppVersion, latestSdkVersion, latestAppVersion
    }
}
