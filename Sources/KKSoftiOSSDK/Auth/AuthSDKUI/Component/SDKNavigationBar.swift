//
//  SDKNavigationBar.swift
//  AuthSDK
//

import SwiftUI

struct SDKNavigationBar: View {
    private let titleKey: LocalizedStringKey?
    private let color: Color?
    private let onBack: (() -> Void)?
    
    init(titleKey: LocalizedStringKey? = nil, color: Color? = nil, onBack: (() -> Void)? = nil) {
        self.titleKey = titleKey
        self.color = color
        self.onBack = onBack
    }
    
    var body: some View {
        ZStack {
            if let color = color {
                color.edgesIgnoringSafeArea(.top)
            }
            Text(titleKey ?? "")
                .font(AppFont.fsClanNarrowUltra.of(size: 16))
                .foregroundColor(.sdkPrimaryReverseText)
            
            if let onBack = onBack {
                HStack {
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.sdkPrimaryReverseText)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    Spacer()
                }
            }
        }
    }
}
#Preview {
    SDKNavigationBar(titleKey: .sdkAsset("step_x_of_y", 2, 3), onBack: {
        
    })
}
