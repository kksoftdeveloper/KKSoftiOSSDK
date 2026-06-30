//
//  AnalyticProperties.swift
//  AuthSDK
//
//  Created by X on 5/10/25.
//

import Foundation
internal import Mixpanel

protocol AnalyticsProperties: SDKInfo, DeviceIdentifiable {
    var platform: String { get }
    var token: String { get }
    var request: String { get }
    var success: String { get }
    var failure: String { get }
    
    var logout: String { get }
}

extension AnalyticsProperties {
    var token: String {
        return Environment.mixpanelKey
    }
    
    var request: String { "request" }
    
    var success: String { "success" }
    
    var failure: String { "failure" }
    
    var logout: String { "logout" }
    
    var getLatestAuthSession: String { "getLatestAuthSession" }
}
