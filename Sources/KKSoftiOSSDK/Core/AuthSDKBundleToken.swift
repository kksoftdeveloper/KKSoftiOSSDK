//
//  AuthSDKBundleToken.swift
//  AuthSDK
//
//  Created by X on 4/25/25.
//

import Foundation
import SwiftUI

private class AuthSDKBundleToken {}

extension Bundle {
    static var authSDK: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: AuthSDKBundleToken.self)
        #endif
    }
}

extension Image {
    init(sdkAsset name: String) {
        self.init(name, bundle: .authSDK)
    }
}

extension Color {
    init(sdkAsset name: String) {
        self.init(name, bundle: .authSDK)
    }
}

extension LocalizedStringKey {
    /// Usage: `Text(.sdk("login_button"))`
    static func sdkAsset(_ key: String) -> LocalizedStringKey {

        let localized: String = String(
            localized: String.LocalizationValue(key),
            table: "Localization",
            bundle: .authSDK,
            comment: ""
        )
        
        return LocalizedStringKey(stringLiteral: localized)
    }
    
    func toString() -> String {
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let value = child.value as? String {
                return value
            }
        }
        return ""
        
    }
    
    static func sdkAsset(_ key: String, _ args: CVarArg...) -> LocalizedStringKey {
        
        let format: String = String(
            localized: String.LocalizationValue(key),
            table: "Localization",
            bundle: .authSDK,
            comment: ""
        )
        
        let localized = String(
            format: format,
            locale: .current,
            arguments: args
        )
        
        return LocalizedStringKey(stringLiteral: localized)
    }
}
