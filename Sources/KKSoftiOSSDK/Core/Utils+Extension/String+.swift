//
//  String+.swift
//  AuthSDK
//

import Foundation
import CryptoKit

extension String {
    func toMD5(salt: [String]) -> String {
        let combinedString = salt.joined()
        let digest = Insecure.MD5.hash(data: Data(combinedString.utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    func isValidPhoneNumber() -> Bool {
        let vnPattern = #"^(?:\+84|0)(?:3[2-9]|5[6|8|9]|7[0|6-9]|8[1-5]|9[0-9])\d{7}$"#
        let regex = try! NSRegularExpression(pattern: vnPattern)
        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
    
    func isValidEmail() -> Bool {
       let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
       return self.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    func isStrongPassword() -> Bool {
        let hasMinLength = self.count >= 8
//        let hasNumber = self.rangeOfCharacter(from: .decimalDigits) != nil
//        let hasSpecialChar = self.rangeOfCharacter(
//            from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",.<>?/")) != nil
//        let hasLetter = self.rangeOfCharacter(from: .letters) != nil
            
//        return hasNumber && hasSpecialChar && hasLetter && hasMinLength
        return hasMinLength
    }
    
    func isValidMd5() -> Bool {
        let md5Regex = "^[a-f0-9]{32}$"
        return self.range(of: md5Regex, options: .regularExpression) != nil
    }

    var configuredValue: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("$(") else { return nil }
        return value
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
