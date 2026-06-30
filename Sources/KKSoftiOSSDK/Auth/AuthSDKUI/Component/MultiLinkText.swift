//
//  ClickableText.swift
//  AuthSDK
//
//  Created by X on 5/13/25.
//

import Foundation
import SwiftUI

struct MultiLinkText:  View {
    let fullText: String
    let links: [LinkItem]
    
    private var attributed: AttributedString {
        var attr = AttributedString(fullText)
        for linkItem in links {
            if let range = attr.range(of: linkItem.substring) {
                attr[range].link = linkItem.url
                // optional styling
                attr[range].foregroundColor = .primaryText
                attr[range].font = AppFont.poppinsBold.of(size: 12)
            }
        }
        return attr
    }
    
    var body: some View {
        Text(attributed)
            .font(AppFont.poppinsLight.of(size: 12))
            .multilineTextAlignment(.center)
            .foregroundColor(.primaryText)
        // if you want to intercept and handle links yourself, uncomment:
        // .onOpenURL { url in … }
    }
}

struct LinkItem {
    let substring: String
    let url: URL
}
