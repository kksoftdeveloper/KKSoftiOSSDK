//
//  MyBackground.swift
//  AuthSDKExample
//
//  Created by X on 4/25/25.
//

import Foundation
import SwiftUI

struct AuthContainer<Content: View, Footer: View>: View {
    
    private let shouldShowCross: Bool
    private let onCloseClick: () -> Void
    private var onLogoTaps: (() -> Void)? = nil
    private let content: () -> Content
    private let footer: () -> Footer
    
    private var wid: CGFloat
    private var hei: CGFloat
    @SwiftUI.Environment(\.verticalSizeClass) private var verticalSizeClass
    
    init(
        wid: CGFloat? = nil,
        hei: CGFloat? = nil,
        shouldShowCross: Bool = true,
        onCloseClick: @escaping () -> Void,
        onLogoTaps: (@escaping () -> Void) = {},
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = {EmptyView()}
    ) {
        self.wid = wid ?? min(UIScreen.main.bounds.size.width, 375)
        self.hei = hei ?? min(UIScreen.main.bounds.size.width, 375) * 1.25
        self.shouldShowCross = shouldShowCross
        self.content = content
        self.onCloseClick = onCloseClick
        self.onLogoTaps = onLogoTaps
        self.footer = footer
    }
    
    private var frameBodyHorizontalInset: CGFloat {
        verticalSizeClass == .regular ? wid * 0.112 : wid * 0.04
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Image(sdkAsset: "BackgroundCircle")
                    .resizable()
                if(verticalSizeClass == .compact) {
                    
                    ZStack(alignment: .top) {
                        
                        Image(sdkAsset: "LogoGame")
                            .resizable()
                            .aspectRatio( contentMode: .fit)
                            .frame(width: wid * 0.3, alignment: .top)
                            .clipped()
                            .padding(.top, -12)
                            .layoutPriority(1)
                            .onTapGesture {
                                (self.onLogoTaps ?? {})()
                            }
                        Spacer()
                            .layoutPriority(8)
                    }
                } else {
                    VStack {
                        Image(sdkAsset: "LogoGame")
                            .layoutPriority(1)
                            .padding(.top, -35)
                            .padding(.leading, 14)
                            .onTapGesture {
                                (self.onLogoTaps ?? {})()
                            }
                        Spacer()
                    }
                }
                content()
                    .padding(.horizontal, frameBodyHorizontalInset)
                    .padding(.vertical, verticalSizeClass == .regular ? 8 : 20)
                    
            }
            .overlay(alignment: .topTrailing, content: {
                let closeButtonSize = wid * 0.13
                if(shouldShowCross) {
                    Button(action: onCloseClick) {
                        Image(sdkAsset: "IconCross")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: closeButtonSize, height: closeButtonSize)
                    }
                    .padding(
                        .horizontal, 23
                    )
                    .padding(.vertical, 8)
                } else {
                    EmptyView()
                }
            })
            
            .frame(
                width: wid,
                height: hei,
                alignment: .center
            )
            footer()
                .frame(maxWidth:  wid)
                .padding(.bottom, verticalSizeClass == .compact ? -6 : -4)
        }
    }
}

#Preview("Portrait") {
    GeometryReader { geo in
        let w = geo.size.width
        let h = geo.size.height
        let isLandscape = w > h
        
        let maxWidth: CGFloat = isLandscape
        ? min(w * 0.6, 600)
        : min(w * 0.9, 375)
        let containerHeight = maxWidth * (isLandscape ? 1.0 : 1.4)
        
        AuthContainer(shouldShowCross: false,
                      onCloseClick: {
            
        }) {
            
        } footer: {
            PrimaryButton(action: {}, label: {
                Text(.sdkAsset("login"))
            }, isDisabled: false)
            .frame(width: 144, height: 32)
        }
        .frame(width: maxWidth, height: containerHeight)
        .frame(
            width: geo.size.width,
            height: geo.size.height,
            alignment: .center
        )
    }
}

@available(iOS 17.0, *)
#Preview("LandscapeLeft",traits: .landscapeLeft) {
    GeometryReader { geo in
        let w = geo.size.width
        let h = geo.size.height
        let isLandscape = w > h
        
        let maxWidth: CGFloat = isLandscape
        ? min(w * 0.6, 600)
        : min(w * 0.9, 375)
        let containerHeight = maxWidth * (isLandscape ? 1.0 : 1.4)
        
        AuthContainer(
            shouldShowCross: false,
            onCloseClick: {
            
            })
        {
            
        } footer: {
            PrimaryButton(action: {}, label: {
                Text(.sdkAsset("login"))
            }, isDisabled: false)
            .frame(width: 144, height: 36)
        }
        .frame(width: maxWidth, height: containerHeight)
        .frame(
            width: geo.size.width,
            height: geo.size.height,
            alignment: .center
        )
    }
}
