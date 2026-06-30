//
//  SecureInputView.swift
//  AuthSDK
//

import SwiftUI

struct SecureInputView: View {
    @Binding var text: String
    @State private var isSecured = true
    private let title: LocalizedStringKey

    init(_ title: LocalizedStringKey, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        HStack {
            Group {
                if isSecured {
                    SecureField(
                        "",
                        text: $text,
                        prompt: Text(title)
                            .font(AppFont.poppinsMedium.of(size: 12))
                            .foregroundColor(.white.opacity(0.35))
                    )
                } else {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(title)
                            .font(AppFont.poppinsMedium.of(size: 12))
                            .foregroundColor(.white.opacity(0.35))
                    )
                }
            }
            .foregroundColor(.white)                           // input text
            .font(AppFont.poppinsMedium.of(size: 12))
            .padding(.vertical, 8)
            .padding(.leading)
            .frame(height: 35)

            Button {
                isSecured.toggle()
            } label: {
                Image(sdkAsset: isSecured ? "eye" : "eye.slash")
                    .foregroundColor(.white)
                    .padding(.trailing)
            }
        }
        .background(Color.darkCocoa)
        .cornerRadius(8)
    }
}

#Preview {
    SecureInputView("Password", text: .constant(""))
        .frame(width: 240)
        .padding()
        .previewLayout(.sizeThatFits)
}
