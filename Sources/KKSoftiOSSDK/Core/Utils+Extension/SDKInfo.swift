//
//  SDKInfo.swift
//  AuthSDK
//

import Foundation

protocol SDKInfo {
    var platform: String { get }
    var versionName: String { get }
    var versionCode: String { get }
}

extension SDKInfo {
    
    var platform: String {
        return "iOS"
    }
    
    var versionName: String {
//        let dictionary = Bundle.
        return "1.0.0" //dictionary?["CFBundleShortSDKVersionString"] as? String ?? "1.0.0"
    }
    
    var versionCode: String {
        let dictionary = Bundle.main.infoDictionary
        return dictionary?["CFBundleSDKVersion"] as? String ?? "1"
    }
    
}
