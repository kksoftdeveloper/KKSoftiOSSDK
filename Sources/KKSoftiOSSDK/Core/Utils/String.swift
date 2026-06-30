import Foundation

extension String {
    func trimmedVietnamPhoneNumber() -> String {
        // Remove all non-digit characters
        let digitsOnly = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        var phone = digitsOnly
        
        // Remove +84 if present
        if phone.hasPrefix("84") {
            phone = String(phone.dropFirst(2))
            if !phone.hasPrefix("0") {
                phone = "0" + phone
            }
        }
        
        return phone
    }
    
    var replacingEscapedNewlines: String {
        self.replacingOccurrences(of: "\\n", with: "\n")
    }
    
    var extractedNumber: String? {
        let pattern = "\\d+"
        if let range = self.range(of: pattern, options: .regularExpression) {
            return String(self[range])
        }
        return nil
    }
    
    var removingNumbers: String {
        return self.replacingOccurrences(of: "\\d+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - String Sanitization Helpers
extension String {
    /// Truncate middle with 3...3 rule
    func truncatedMiddle() -> String {
        let keep = 3
        guard self.count > keep * 2 else { return self }
        return "\(prefix(keep))...\(suffix(keep))"
    }
    
    /// Replace password with same-length masking
    func maskedPassword() -> String {
        guard !self.isEmpty else { return self }
        return String(repeating: "*", count: self.count)
    }
}
