//
//  DeactivateAnalytics.swift
//  AuthSDK
//
//  Created by X on 6/2/25.
//

import Foundation
internal import Mixpanel

protocol DeactivateProperties: SDKInfo, DeviceIdentifiable {
    var platform: String { get }
    var token: String { get }
    var request: String { get }
    var success: String { get }
    var failure: String { get }
    
    var logout: String { get }
}

extension DeactivateProperties {
    var token: String {
        return Environment.mixpanelKey
    }
    
    var request: String { "request" }
    
    var success: String { "success" }
    
    var failure: String { "failure" }
    
    var logout: String { "logout" }
    
    var deactivateAccount: String { "deactivateAccount" }
}
