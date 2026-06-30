//
//  EnvironmentTests.swift
//  AuthSDK
//

import XCTest

final class EnvironmentTests: XCTestCase {

    func testBaseURLForStagingEnvironment() {
        let env = Environment.staging
        XCTAssertEqual(env.baseURL, URL(string: "https://go-staging.tekernal.net")!)
    }

    func testBaseURLForProductionEnvironment() {
        let env = Environment.production
        XCTAssertEqual(env.baseURL, URL(string: "https://go-staging.tekernal.net")!)
    }

    func testCurrentEnvironment() {
        let currentEnv = Environment.current

        #if STAGING
        XCTAssertEqual(currentEnv, .staging, "Should be Staging environment")
        #else
        XCTAssertEqual(currentEnv, .production, "Should be Production environment")
        #endif
    }
}
