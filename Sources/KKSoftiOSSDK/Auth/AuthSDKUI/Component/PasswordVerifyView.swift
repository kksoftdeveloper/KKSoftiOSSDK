//
//  PasswordVerifyView.swift
//  AuthSDK
//

import SwiftUI

struct PasswordVerifyView: View {
    @Binding var password: String
    @Binding var confirmPassword: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            
            ValidationMessageText(textKey: .sdkAsset("password_eight_characters"), size: 8, isValid: password.count >= 8)
            
//            ValidationMessageText(textKey: .sdkAsset("password_one_digit"), size: 8, isValid: password.rangeOfCharacter(from: .decimalDigits) != nil && password.rangeOfCharacter(from: .letters) != nil)
//            
//            ValidationMessageText(textKey: .sdkAsset("password_special_characters"), size: 8, isValid: password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",.<>?/")) != nil)
            
            ValidationMessageText(textKey: .sdkAsset("password_same"), size: 8, isValid: password == confirmPassword && password.count > 0)
        }
        .padding(.vertical, 2)
    }
}
