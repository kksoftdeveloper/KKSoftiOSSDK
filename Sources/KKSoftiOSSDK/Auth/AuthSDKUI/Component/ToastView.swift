//
//  ToastView.swift
//  AuthSDK
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let message = message {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.sdkPrimaryText)
                        .padding()
                        .background(Color.sdkPrimaryButtonBackground.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: message)
                }
            }
        }
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        self.modifier(ToastModifier(message: message))
    }
}
