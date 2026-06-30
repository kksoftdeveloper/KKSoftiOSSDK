//
//  File.swift
//  AuthSDK
//
//  Created by Admin on 4/27/25.
//

import Foundation
import SwiftUI

struct UnderlinedButton: View {
    var title: LocalizedStringKey
    var action: () -> Void
    var font: Font = AppFont.poppinsBold.of(size: 12)
    var textColor: Color = .accentColor
    var underlineColor: Color? = nil  // if nil, uses textColor

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundColor(textColor)
                .underline(true, color: underlineColor ?? textColor)
        }
        // remove the default button highlighting so it looks like plain text
        .buttonStyle(.plain)
    }
}

#Preview {
    UnderlinedButton(title: "Login") {
        
    }
}
