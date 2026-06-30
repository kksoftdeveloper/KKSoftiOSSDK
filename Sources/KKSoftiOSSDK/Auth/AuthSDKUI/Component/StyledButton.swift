//
//  StyledButton.swift
//  AuthSDK
//

import SwiftUI

public struct StyledButton: View {
    let title: LocalizedStringKey
    let bgColor: Color
    let isEnabled: Bool
    let action: () -> Void

    public init(_ title: LocalizedStringKey, bgColor: Color, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.bgColor = bgColor
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.sdkPrimaryText)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .background(bgColor)
            .cornerRadius(8)
            .opacity(isEnabled ? 1 : 0.5)
        }
        .disabled(!isEnabled)
    }
}
