//
//  GameInfo.swift
//  AuthSDK
//

import Foundation

struct VersionInfoServerDTO: Decodable {
    
    let forceUpdate: Bool
    let minSdkVersion: String
    let minAppVersion: String
    let latestSdkVersion: String
    let latestAppVersion: String
    
    enum VersionInfoServerDTO: String, Codable {
        case forceUpdate, minSdkVersion, minAppVersion, latestSdkVersion, latestAppVersion
    }
}

extension VersionInfoServerDTO {
    
    func toModel() -> VersionInfoModel {
        return VersionInfoModel(forceUpdate: forceUpdate, minSdkVersion: minSdkVersion, minAppVersion: minAppVersion, latestSdkVersion: latestSdkVersion, latestAppVersion: latestAppVersion)
    }
}
