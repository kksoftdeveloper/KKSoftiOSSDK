//
//  OTPTextField.swift
//  AuthSDK
//

import SwiftUI

public struct OTPTextField: View {
    let numberOfFields: Int
    
    @FocusState private var isFocused: Bool
    
    @Binding var otpText: String

    public init(numberOfFields: Int = 6, otpText: Binding<String>) {
        self.numberOfFields = numberOfFields
        self._otpText = otpText
    }

    public var body: some View {
        VStack {
            HStack(spacing: 8) {
                ForEach(0..<numberOfFields, id: \.self) { idx in
                    OTPDigitBox(
                        character: character(at: idx)
                    )
                }
            }
            .overlay {
                TextField("", text: $otpText.limited(to: numberOfFields))
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isFocused)
                    .frame(width: 0, height: 0)
                    .opacity(0.01)
                    .onChange(of: otpText) { new in
                        if new.count == numberOfFields {
                            isFocused = false
                        }
                    }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
        }
        .onAppear {
            // auto-focus when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }

    private func character(at index: Int) -> String {
        guard index < otpText.count else { return "" }
        let idx = otpText.index(otpText.startIndex, offsetBy: index)
        return String(otpText[idx])
    }
}

private struct OTPDigitBox: View {
    let character: String

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.darkCocoa)
                    .frame(width: geo.size.height * (33.0 / 40.0), height: geo.size.height)
                
                Text(character)
                    .font(AppFont.poppinsLight.of(size: 14))
                    .foregroundColor(.white)
            }
        }
        .aspectRatio(33.0 / 40.0, contentMode: .fit)
    }
}

private extension Binding where Value == String {
    func limited(to length: Int) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue },
            set: { new in
                self.wrappedValue = String(new.prefix(length))
            }
        )
    }
}

#Preview {
    OTPTextField(numberOfFields: 2, otpText: .constant("123"))
        .padding()
        .previewLayout(.sizeThatFits)
}
