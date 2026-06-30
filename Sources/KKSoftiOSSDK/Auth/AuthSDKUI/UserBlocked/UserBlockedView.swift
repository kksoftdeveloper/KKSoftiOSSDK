//
//  MaintanceServerView.swift
//  AuthSDK
//
//  Created by X on 5/13/25.
//

import Foundation
import SwiftUI

public struct UserBlockedView: View {
    
    private let phoneNumber: String
    private let fanpage: String
    private let onClose: () -> Void
    
    let pattern = LocalizedStringKey.sdkAsset("user_blocked_subtitle").toString()
    let phone   = LocalizedStringKey.sdkAsset("cskh").toString()
    let website = LocalizedStringKey.sdkAsset("fanpage").toString()
    
    public init(phoneNumber: String,
         fanpage: String,
         onClose: @escaping () -> Void) {
        self.phoneNumber = phoneNumber
        self.fanpage = fanpage
        self.onClose = onClose
    }
    
    public var body: some View {
        let full = String(format: pattern, website, phone)
        SquareContainer(
            shouldShowCross: false,
            onCloseClick: {
                
            },
            content: {
                VStack {
                    Text(.sdkAsset("user_blocked_title"))
                        .font(AppFont.fsClanNarrowUltra.of(size: 16))
                        .foregroundColor(.primaryText)
                        .padding(.vertical, 15)
                    MultiLinkText(
                         fullText: full,
                         links: [
                            .init(substring: website, url: URL(string: fanpage)!),
                            .init(substring: phone,   url: URL(string: "tel:\(phoneNumber)")!)
                         ]
                       )
                    .padding(.horizontal, 50)

                }
            },
            footer: {
                PrimaryButton(
                    action: {
                        onClose()
                    },
                    label: {
                        Text(.sdkAsset("close"))
                    },
                    isDisabled: false
                )
                .frame(width: 144, height: 36)
            }
        )
    }
}

#Preview {
    ServerMaintenanceView(
        phoneNumber: "+84918247267",
        fanpage: "https://www.apple.com/",
        onUpdatedGameServer:   { a, b in
            
        })
}
