//
//  RefreshTokenAnalytics.swift
//  AuthSDK
//
//  Created by X on 5/13/25.
//

import Foundation
internal import Mixpanel

protocol RefreshTokenAnalytics: AnalyticsProperties {
    var eventName: String { get }
}

extension RefreshTokenAnalytics {
    var eventName: String { "refreshToken" }
    
    
    
}
