//
//  ForgotPasswordAnalytics.swift
//  AuthSDK
//
//  Created by X on 5/13/25.
//

import Foundation
internal import Mixpanel

protocol ForgotPasswordAnalytics: AnalyticsProperties {
    var eventName: String { get }
    var requestOTP: String { get }
    var verifyOTP: String { get }
}

extension ForgotPasswordAnalytics {
    var eventName: String { "forgotPassword" }
    var requestOTP: String { "forgotPasswordRequestOTP" }
    var verifyOTP: String { "forgotPasswordVerifyOTP" }
}
