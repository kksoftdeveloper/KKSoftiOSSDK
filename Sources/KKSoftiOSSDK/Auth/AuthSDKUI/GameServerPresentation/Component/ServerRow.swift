//
//  ServerRow.swift
//  AuthSDK
//
//  Created by X on 5/8/25.
//

import Foundation
import SwiftUI

struct ServerRow: View {
    let server: GameServerInfoResponse
    let isSelected: Bool
    
    var body: some View {
        HStack {
            getLeadingIcon()

            Text(server.serverName)
                .font(AppFont.poppinsSemiBold.of(size: 12))
                .foregroundColor(Color.primaryText)

            Spacer()
            
            Text(localizationStatus())
                .font(AppFont.poppinsRegular.of(size: 10))
                .foregroundColor(getIndicatorColor())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? getIndicatorColor() : .clear, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.dustyOlive)
                )
        )
        .padding(.horizontal)
    }
}

extension ServerRow {
    
    @ViewBuilder
    func getLeadingIcon() -> some View {
        if server.serverStatus == .online {
            Image(sdkAsset: "IconGreenBall")
                .frame(width: 16, height: 16)
        } else {
            Image(sdkAsset: "IconGreyBall")
                .frame(width: 16, height: 16)
        }
    }
    
    func getIndicatorColor() -> Color {
        if server.serverStatus == .online {
            Color(sdkAsset: "ColorLightGreen")
        } else {
            Color.ashGray
        }
    }
    
    func localizationStatus() -> String {
        return server.serverStatus.rawValue.lowercased().capitalizingFirstLetter()
    }
}

