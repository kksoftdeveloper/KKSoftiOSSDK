//
//  Analytics.swift
//  AuthSDK
//
//  Created by X on 5/10/25.
//

import Foundation

internal import Mixpanel

enum BaseAnalytics {
    private static var _mixpanel: MixpanelInstance?
    private static let lock = NSLock()
    
    public static func initialize(token: String) {
        lock.lock(); defer { lock.unlock() }
        guard _mixpanel == nil else { return }
        _mixpanel = Mixpanel.initialize(token: token, trackAutomaticEvents: true)
    }
    
    private static var mixpanel: MixpanelInstance {
        guard let instance = _mixpanel else {
            fatalError("Mixpanel not initialized! Call Analytics.initialize(token:) before tracking events.")
        }
        return instance
    }
    
    static func identify(userId: String) {
        let mp = mixpanel
        mp.identify(distinctId: userId)
        mp.people.set(properties: ["$distinct_id": userId])
    }
    
    static func track(event: String, properties: Properties? = nil) {
        mixpanel.track(
            event: event,
            properties: properties
        )
    }
    
    static func flush() {
        mixpanel.flush()
    }
}
