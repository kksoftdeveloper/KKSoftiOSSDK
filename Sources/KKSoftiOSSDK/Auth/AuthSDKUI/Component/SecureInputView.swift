//
//  SecureInputView.swift
//  AuthSDK
//

import SwiftUI

struct SecureInputView: View {
    @Binding var text: String
    @State private var isSecured = true
    private let title: LocalizedStringKey
    private let height: CGFloat

    init(_ title: LocalizedStringKey, text: Binding<String>, height: CGFloat = 35) {
        self.title = title
        self._text = text
        self.height = height
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
            .frame(height: height)

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
        .frame(height: height)
    }
}

#Preview {
    SecureInputView("Password", text: .constant(""))
        .frame(width: 240)
        .padding()
        .previewLayout(.sizeThatFits)
}
