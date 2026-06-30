//
//  GuestLoginAnalytics.swift
//  AuthSDK
//
//  Created by X on 5/13/25.
//

import Foundation
internal import Mixpanel

protocol LoginAnalytics: AnalyticsProperties {
    var guestLogin: String { get }
    var phoneLogin: String { get }
    var facebookLogin: String { get }
    var googleLogin: String { get }
    var appleLogin: String { get }
}

extension LoginAnalytics {
    var guestLogin: String { "guestLogin" }
    var phoneLogin: String { "phoneLogin" }
    var facebookLogin: String { "facebookLogin" }
    var googleLogin: String { "googleLogin" }
    var appleLogin: String { "appleLogin" }
}
