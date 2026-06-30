//
//  GameInfoModel.swift
//  AuthSDK
//

import Foundation

struct VersionInfoModel {
    let forceUpdate: Bool
    let minSdkVersion: String
    let minAppVersion: String
    let latestSdkVersion: String
    let latestAppVersion: String
}

extension VersionInfoModel {
    func toResponse() -> VersionInfoResponse {
        return VersionInfoResponse(forceUpdate: forceUpdate, minSdkVersion: minSdkVersion, minAppVersion: minAppVersion, latestSdkVersion: latestSdkVersion, latestAppVersion: latestAppVersion)
    }
}
