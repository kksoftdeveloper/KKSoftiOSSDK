import SwiftUI
import CoreGraphics
import CoreText
import Foundation

public class FontLoader {
    private static func loadFont(named name: String, bundle: Bundle? = nil) {
        let resolvedBundle = bundle ?? .authSDK
        
        guard let url = resolvedBundle.url(forResource: name, withExtension: nil) else {
            print("⚠️ Could not find font \(name)")
            return
        }
        
        guard let dataProvider = CGDataProvider(url: url as CFURL),
              let font = CGFont(dataProvider) else {
            print("⚠️ Could not load font from \(url)")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            print("⚠️ Failed to register font: \(error?.takeUnretainedValue().localizedDescription ?? "unknown error")")
        } else {
            print("✅ Successfully registered font: \(name)")
        }
    }
    
    public static func loadAllFonts() {
        FontLoader.loadFont(named: "FS-ClanPro-NarrowUltra.ttf")
        FontLoader.loadFont(named: "Poppins-Bold.ttf")
        FontLoader.loadFont(named: "Poppins-Light.ttf")
        FontLoader.loadFont(named: "Poppins-LightItalic.ttf")
        FontLoader.loadFont(named: "Poppins-Medium.ttf")
        FontLoader.loadFont(named: "Poppins-Regular.ttf")
        FontLoader.loadFont(named: "Poppins-SemiBold.ttf")
        FontLoader.loadFont(named: "Poppins-Thin.ttf")
        FontLoader.loadFont(named: "Dongle-Bold.ttf")
        FontLoader.loadFont(named: "Dongle-Light.ttf")
        FontLoader.loadFont(named: "Dongle-Regular.ttf")
    }
}
