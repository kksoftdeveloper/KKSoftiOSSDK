//
//  OTPAnalytics.swift
//  AuthSDK
//
//  Created by X on 5/13/25.
//

import Foundation
internal import Mixpanel

protocol OTPAnalytics: AnalyticsProperties {
    var requestOTP: String { get }
    var verifyOTP: String { get }
}

extension OTPAnalytics {
    var requestOTP: String { "requestOTP" }
    var verifyOTP: String { "verifyOTP" }
}
