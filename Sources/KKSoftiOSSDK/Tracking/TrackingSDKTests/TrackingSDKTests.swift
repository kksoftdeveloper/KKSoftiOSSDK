//
//  TrackingSDKTests.swift
//  TrackingSDKTests
//
//  Created on 11/4/25.
//

import XCTest

final class TrackingSDKTests: XCTestCase {
    
    func testTrackingServiceProviderBuilder() {
        let service = TrackingServiceProvider.Builder()
            .enableAppFlyers(appID: "test-app-id", devKey: "test-dev-key")
            .build()
        
        XCTAssertNotNil(service.trackingManager)
    }
    
    func testTrackingManagerInitialization() {
        let service = TrackingServiceProvider.Builder()
            .enableAppFlyers(appID: "test-app-id", devKey: "test-dev-key")
            .build()
        
        service.trackingManager.initialize()
        // If no exception is thrown, initialization succeeded
    }
    
    func testTrackEvent() {
        let service = TrackingServiceProvider.Builder()
            .enableAppFlyers(appID: "test-app-id", devKey: "test-dev-key")
            .build()
        
        service.trackingManager.initialize()
        service.trackingManager.trackEvent("test_event", parameters: ["key": "value"])
        // If no exception is thrown, tracking succeeded
    }
    
    func testPredefinedEvents() {
        let service = TrackingServiceProvider.Builder()
            .enableAppFlyers(appID: "test-app-id", devKey: "test-dev-key")
            .build()
        
        service.trackingManager.initialize()
        service.trackingManager.trackEvent(.userLogin, parameters: ["method": "email"])
        // If no exception is thrown, tracking succeeded
    }
}

