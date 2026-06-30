import SwiftUI

struct ValidationMessageText: View {
    let textKey: LocalizedStringKey?
    var size: CGFloat = 12
    var isValid: Bool? = nil

    var body: some View {
        if let key = textKey {
            HStack(spacing: 8) {
                if let isValid = isValid {
                    Image(sdkAsset: isValid ? "IconChecked" : "IconClose")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                
                Text(key.toString().replacingEscapedNewlines)
                    .font(AppFont.poppinsRegular.of(size: size))
                    .foregroundColor(isValid ?? false ? Color.primaryText : Color.redish)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    ValidationMessageText(
        textKey: .sdkAsset("incorrect_otp"),
        size: 10
    )
    
//    ValidationMessageText(textKey: .sdkAsset("incorrect_otp"), size: 12, isValid: false)
}
