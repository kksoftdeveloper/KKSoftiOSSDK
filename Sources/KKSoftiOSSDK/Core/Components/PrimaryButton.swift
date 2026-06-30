//
//  PrimaryButton.swift
//  AuthSDK
//
//  Created by X on 4/25/25.
//

import Foundation
import SwiftUI

public struct PrimaryButton<Label: View>: View {
    public let action: () -> Void
    public let label: () -> Label
    public let isDisabled: Bool
    
    public init(
        action: @escaping () -> Void,
        label: @escaping () -> Label,
        isDisabled: Bool = false
    ) {
        self.action = action
        self.label = label
        self.isDisabled = isDisabled
    }

    let enabledBackground: Image = Image(sdkAsset: "BackgroundActiveBtn")
    let disabledBackground: Image = Image(sdkAsset: "BackgroundUnactiveBtn")
    
    let enabledLabelColor: Color = .white
    let disabledLabelColor: Color = .white.opacity(0.7)
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                (isDisabled ? disabledBackground : enabledBackground)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
                
                label()
                    .font(AppFont.fsClanNarrowUltra.of(size: 16))
                    .foregroundColor(isDisabled ? disabledLabelColor : enabledLabelColor)
                    .padding(.vertical, 6)
            }
        }
        .disabled(isDisabled)
    }
}

#Preview {
    PrimaryButton(action: {}, label: {
        Text("Đăng nhập")
    }, isDisabled: false)
    .frame(width: 140, height: 24)
}
