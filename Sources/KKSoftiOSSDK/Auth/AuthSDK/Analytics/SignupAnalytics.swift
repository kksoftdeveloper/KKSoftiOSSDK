//
//  SignupAnalytics.swift
//  AuthSDK
//
//  Created by X on 5/13/25.
//

import Foundation
internal import Mixpanel

protocol SignupAnalytics: AnalyticsProperties {
    var phoneSignup: String { get }
    var linkToPhoneAccount: String { get }
    var linkToFacebookAccount: String { get }
    var linkToGoogleAccount: String { get }
}

extension SignupAnalytics {
    var phoneSignup: String { "phoneSignup" }
    
    var updateAccountInfo: String { "updateAccountInfo" }
    
    var linkToPhoneAccount: String { "linkToPhoneAccount" }
    
    var linkToFacebookAccount: String { "linkToFacebookAccount" }
    
    var linkToGoogleAccount: String { "linkToGoogleAccount" }
}
