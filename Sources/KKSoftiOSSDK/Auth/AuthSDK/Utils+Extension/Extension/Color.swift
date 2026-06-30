//
//  Color.swift
//  AuthSDK
//

import SwiftUI

extension Color {
    static var sdkPrimaryText: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .white
        })
    }
    
    static var sdkSecondaryText: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .lightGray : .darkGray
        })
    }
    
    static var sdkPrimaryReverseText: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    static var sdkPrimaryButtonBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    static var sdkSecondaryButtonBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .darkGray: .systemGray2
        })
    }
    
    static var sdkBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .white
        })
    }
}

