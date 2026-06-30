//
//  KeychainSessionManagerTests.swift
//  AuthSDK
//

//import XCTest
//
//
//final class KeychainSessionManagerTests: XCTestCase {
//    
//    var sessionManager: SessionManager!
//    
//    override func setUp() {
//        super.setUp()
//        sessionManager = KeyChainSessionManager()
//        try? sessionManager.clear() // Ensure clean state before each test
//    }
//
//    override func tearDown() {
//        try? sessionManager.clear() // Cleanup after each test
//        sessionManager = nil
//        super.tearDown()
//    }
//
//    // MARK: - Test Saving and Retrieving Session
//    func testSaveAndRetrieveSession() throws {
//        let testSession = AuthSessionModel(
//            accessToken: "testAccess123",
//            refreshToken: "testRefresh456",
//            expiresIn: Date().addingTimeInterval(3600)
//        )
//        
//        // Save session
//        XCTAssertNoThrow(try sessionManager.saveSession(authSession: testSession), "Saving session should not throw an error.")
//        
//        // Retrieve session
//        let retrievedSession = try sessionManager.getSession()
//        
//        // Validate session data
//        XCTAssertNotNil(retrievedSession, "Session should be retrievable.")
//        XCTAssertEqual(retrievedSession?.accessToken, "testAccess123")
//        XCTAssertEqual(retrievedSession?.refreshToken, "testRefresh456")
//    }
//
//    // MARK: - Test Clearing Session
//    func testClearSession() throws {
//        let testSession = AuthSessionModel(
//            accessToken: "testAccess123",
//            refreshToken: "testRefresh456",
//            expiresIn: Date().addingTimeInterval(3600)
//        )
//        
//        // Save session
//        try sessionManager.saveSession(authSession: testSession)
//        
//        // Clear session
//        XCTAssertNoThrow(try sessionManager.clear(), "Clearing session should not throw an error.")
//
//        // Ensure session is cleared
//        let retrievedSession = try sessionManager.getSession()
//        XCTAssertNil(retrievedSession, "Session should be nil after clearing.")
//    }
//
//    // MARK: - Test Retrieving Non-Existent Session
//    func testRetrieveNonExistentSession() throws {
//        let retrievedSession = try sessionManager.getSession()
//        XCTAssertNil(retrievedSession, "Retrieving session when none exists should return nil.")
//    }
//}
