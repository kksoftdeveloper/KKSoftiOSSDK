//
//  InitializeAnalytics.swift
//  AuthSDK
//
//  Created by X on 5/12/25.
//

import Foundation
internal import Mixpanel

protocol InitializeAnalytics: AnalyticsProperties {
    var eventName: String { get }   
}

extension InitializeAnalytics {
    var eventName: String { "initAuthSDK" }
}
