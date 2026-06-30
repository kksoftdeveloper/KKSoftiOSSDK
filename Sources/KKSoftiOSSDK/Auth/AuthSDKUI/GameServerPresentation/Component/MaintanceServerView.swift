//
//  MaintanceServerView.swift
//  AuthSDK
//
//  Created by X on 5/13/25.
//

import Foundation
import SwiftUI

public struct ServerMaintenanceView: View {
    
    private let phoneNumber: String
    private let fanpage: String
    
    private let onUpdatedGameServer: (Int?, String?) -> Void
    
    let pattern = LocalizedStringKey.sdkAsset("maintenance_subtitle").toString()
    let phone   = LocalizedStringKey.sdkAsset("cskh").toString()
    let website = LocalizedStringKey.sdkAsset("fanpage").toString()
    
    public init(phoneNumber: String,
         fanpage: String,
         onUpdatedGameServer: @escaping (Int?, String?) -> Void) {
        self.onUpdatedGameServer = onUpdatedGameServer
        self.phoneNumber = phoneNumber
        self.fanpage = fanpage
    }
    
    public var body: some View {
        let full = String(format: pattern, website, phone)
        SquareContainer(
            shouldShowCross: false ,
            onCloseClick: { },
            content: {
                VStack {
                    Text(.sdkAsset("maintenance_title"))
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
            }
//            footer: {
//                PrimaryButton(
//                    action: {
//                        onUpdatedGameServer(nil, nil)
//                    },
//                    label: {
//                        Text(.sdkAsset("close"))
//                    },
//                    isDisabled: false
//                )
//                .frame(width: 144, height: 36)
//            }
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
