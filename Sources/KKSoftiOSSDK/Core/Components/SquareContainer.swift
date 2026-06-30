//
//  File.swift
//  AuthSDK
//
//  Created by Admin on 4/29/25.
//

import Foundation
import SwiftUI

struct SquareContainer<Content: View, Footer: View>: View {
    
    private let shouldShowCross: Bool
    private let onCloseClick: () -> Void
    private let content: () -> Content
    private let footer: () -> Footer
    
    init(
        shouldShowCross: Bool = true,
        onCloseClick: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = {EmptyView()}
    ) {
        self.shouldShowCross = shouldShowCross
        self.content = content
        self.onCloseClick = onCloseClick
        self.footer = footer
    }
    
    var body: some View {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let minValue = min(width, height, 440)
        let contentWidth = minValue
        let contentHeight = minValue*0.6
        
        ZStack() {
            Image(sdkAsset: "RectangleBackground")
                .resizable()
            
            content()
        }
        .frame(width: contentWidth, height: contentHeight)
        .overlay(alignment: .topTrailing, content: {
            if(shouldShowCross) {
                Button(action: onCloseClick) {
                    Image(sdkAsset: "IconCross")
                }
                .padding(.horizontal, contentWidth/16)
                .padding(.vertical, 8)
            } else {
                EmptyView()
            }
        })
        .overlay(alignment: .bottom, content: {
            let footerWidth = contentWidth*0.46
            footer()
                .frame(width: footerWidth, height: footerWidth*0.35)
                .padding(.bottom, -contentWidth/12)
        })
    }
}

#Preview {
    SquareContainer(
        shouldShowCross: true,
        onCloseClick: {
            
        })
    {
    } footer: {
        PrimaryButton(action: {}, label: {
            Text(.sdkAsset("login"))
        }, isDisabled: (false))
        .frame(width: 144, height: 36)
    }
}
