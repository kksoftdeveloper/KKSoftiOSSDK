//
//  VersionInfoDTO.swift
//  AuthSDK
//
//  Created by X on 4/29/25.
//

import Foundation

struct VersionInfoResponseDTO: Decodable {
    let forceUpdate: Bool
    let minSdkVersion: String
    let minAppVersion: String
    let latestSdkVersion: String
    let latestAppVersion: String
}

extension VersionInfoResponseDTO {
    func toModel() -> VersionInfoModel {
        return VersionInfoModel(
            forceUpdate: forceUpdate,
            minSdkVersion: minAppVersion,
            minAppVersion: minAppVersion,
            latestSdkVersion: latestSdkVersion,
            latestAppVersion: latestAppVersion
        )
    }
}
