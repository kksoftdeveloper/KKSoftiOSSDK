//
//  StringMD5ValidationTests.swift
//  AuthSDKTests
//
//  Created by X on 5/19/25.
//

import XCTest

final class StringMD5ValidationTests: XCTestCase {

    func testIsValidMd5_withValidLowercaseHex_returnsTrue() {
        // 32 lowercase hex characters
        let valid = "1e4d2f8b5c6a7d8e9f0a1b2c3d4e5f6a"
        XCTAssertTrue(valid.isValidMd5(), "Expected lowercase hex MD5 to be valid")
    }

    func testIsValidMd5_withUppercaseHex_returnsFalse() {
        // uppercase hex should fail against [a-f0-9] regex
        let uppercase = "1E4D2F8B5C6A7D8E9F0A1B2C3D4E5F6A"
        XCTAssertFalse(uppercase.isValidMd5(), "Uppercase hex should not match lowercase-only regex")
    }

    func testIsValidMd5_withInvalidCharacters_returnsFalse() {
        // includes 'g' which is outside a–f
        let invalidChars = "g1234567890abcdef1234567890abcdef"
        XCTAssertFalse(invalidChars.isValidMd5(), "'g' is not a valid hex digit")
    }

    func testIsValidMd5_withWrongLength_returnsFalse() {
        // too short (31 chars)
        let tooShort = "1e4d2f8b5c6a7d8e9f0a1b2c3d4e5f6"
        // too long (33 chars)
        let tooLong  = "1e4d2f8b5c6a7d8e9f0a1b2c3d4e5f6aa"
        XCTAssertFalse(tooShort.isValidMd5(), "31‐char string should be invalid")
        XCTAssertFalse(tooLong.isValidMd5(),  "33‐char string should be invalid")
    }

    func testIsValidMd5_withEmptyString_returnsFalse() {
        XCTAssertFalse("".isValidMd5(), "Empty string should not be considered a valid MD5")
    }
}
