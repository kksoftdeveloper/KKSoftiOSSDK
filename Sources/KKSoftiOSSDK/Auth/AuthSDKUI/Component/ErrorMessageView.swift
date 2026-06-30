//
//  ErrorMessageView.swift
//  AuthSDK
//
//  Created by X on 8/8/25.
//

import SwiftUI

struct ErrorMessageView: View {
    let textKey: String?
    var size: CGFloat = 12
    
    init(textKey: String?, size: CGFloat = 12) {
        self.textKey = textKey
        if textKey == LocalizedStringKey.sdkAsset("account_is_deleted").toString() {
            self.size = 9
        } else {
            self.size = size
        }
    }
    
    var body: some View {
        if let key = textKey {
            HStack(spacing: 8) {
                Image(sdkAsset: "IconClose")
                    .resizable()
                    .frame(width: 16, height: 16)
                
                Text(key)
                    .font(AppFont.poppinsRegular.of(size: size))
                    .foregroundColor( Color.redish)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

