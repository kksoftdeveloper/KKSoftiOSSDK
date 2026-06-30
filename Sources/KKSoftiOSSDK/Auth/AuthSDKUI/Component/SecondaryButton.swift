//
//  SecondaryButton.swift
//  AuthSDKExample
//
//  Created by X on 4/25/25.
//

import Foundation
import SwiftUI


struct SecondaryButton<Label: View>: View {
    let action: () -> Void                  // what happens when tapped
    let isDisabled: Bool                    // control enabled/disabled state
    let content: () -> Label                // icon/text/whatever you want inside
    
    let background: AnyView                 // background view (color, gradient, image…)
    let disabledBackground: AnyView         // background when disabled
    let cornerRadius: CGFloat               // how round the corners are
    let pressedOpacity: Double              // tap-state feedback
    let disabledOpacity: Double             // how faded when disabled
    
    init(
        isDisabled: Bool = false,
        cornerRadius: CGFloat = 8,
        pressedOpacity: Double = 0.7,
        disabledOpacity: Double = 0.6,
        background: AnyView = AnyView(Color(sdkAsset: "ColorBrownish")),
        disabledBackground: AnyView? = nil,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Label
    ) {
        self.isDisabled = isDisabled
        self.cornerRadius = cornerRadius
        self.pressedOpacity = pressedOpacity
        self.disabledOpacity = disabledOpacity
        self.background = background
        // fall back to the same background if no disabled provided
        self.disabledBackground = disabledBackground ?? background
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: action) {
            content()
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
        .background(
            Group {
                if isDisabled { disabledBackground }
                else { background }
            }
        )
        .cornerRadius(cornerRadius)
        .opacity(isDisabled ? disabledOpacity : 1)
        .buttonStyle(PlainButtonStyle())
        //             .scaleEffect(configuration.isPressed ? pressedOpacity : 1)
        .disabled(isDisabled)
    }
}

#Preview {
    HStack {
        SecondaryButton(
            action: {
            },
            content: {
                Image(sdkAsset: "IconGoogle")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        )
        .layoutPriority(1)
        
        SecondaryButton(
            action: {
            },
            content: {
                Image(sdkAsset: "IconFacebook")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        )
        .layoutPriority(1)
        
        SecondaryButton(action: {
        }, content: {
            HStack {
                Image(sdkAsset: "IconPlay")
                    .resizable()
                    .renderingMode(.original)
                    .frame(width: 16, height: 16)
                
                Text(.sdkAsset("play_now"))
                    .foregroundColor(.white)
            }
        })
        .layoutPriority(2)
    }
    .padding(56)
}
