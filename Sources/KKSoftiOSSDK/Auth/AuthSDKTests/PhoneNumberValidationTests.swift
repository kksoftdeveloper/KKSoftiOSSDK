//
//  PhoneNumberValidationTests.swift
//  AuthSDK
//
//  Created by X on 5/19/25.
//

import XCTest

final class PhoneNumberValidationTests: XCTestCase {

    func testValidVietnamesePhoneNumbers() {
        let validNumbers = [
            "+84321234567",
            "0321234567",
            "0581234567",
            "0791234567",
//            "0871234567",
            "0901234567",
            "0991234567"
        ]

        for number in validNumbers {
            XCTAssertTrue(
                number.isValidPhoneNumber(),
                "Expected “\(number)” to be recognized as a valid VN phone number"
            )
        }
    }

    func testInvalidVietnamesePhoneNumbers() {
        let invalidNumbers = [
            "12345678",           // too short
            "+8412123456",        // wrong length
            "0412345678",         // bad prefix
            "+849012345678",      // too many digits
            "090123456",          // one digit too few
            "0a01234567",         // non-digit characters
            "+840901234567"       // incorrect country code formatting
        ]

        for number in invalidNumbers {
            XCTAssertFalse(
                number.isValidPhoneNumber(),
                "Expected “\(number)” to be rejected as an invalid VN phone number"
            )
        }
    }
}
