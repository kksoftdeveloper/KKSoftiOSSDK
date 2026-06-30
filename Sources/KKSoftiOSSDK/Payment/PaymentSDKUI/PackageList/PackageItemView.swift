import SwiftUI
import StoreKit

struct PackageItemView: View {
    let item: PackageItemModel
    let action: () -> Void
    let isGuestUser: Bool
    
    @State private var disabled: Bool = false
    @State private var disableText: String? = nil
    
    private let fullWidth = min( UIScreen.main.bounds.size.width, 375)
    private var isIPhone = UIDevice.current.userInterfaceIdiom == .phone
    private var isLandscapeOnIPhone: Bool {
        isIPhone && orientationObserver.isLandscape
    }
    @StateObject private var orientationObserver = OrientationObserver()
    
    init(item: PackageItemModel, isGuestUser: Bool, action: @escaping () -> Void) {
        self.item = item
        self.action = action
        self.isGuestUser = isGuestUser
    }
    
    private var pointText: String {
        "\(item.displayPoints)"
    }
    
    private var alias: String {
        if let alias = item.alias {
            return "\(alias)"
        }
        return ""
    }
    
    var body: some View {
        ZStack (alignment: .bottomTrailing){
            HStack{
                ZStack(alignment: .bottomTrailing) {
                    Image(sdkAsset: "package_photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isLandscapeOnIPhone ? 35 : 50, height: isLandscapeOnIPhone ? 35 : 50)
                        .cornerRadius(5)
                    Text(pointText)
                        .font(AppFont.dongleBold.of(size: isLandscapeOnIPhone ? 14 : 20))
                        .foregroundColor(.white)
                        .padding(.bottom, -5)
                        .padding(.trailing, 5)
                }

                VStack(alignment: .leading, spacing: -15) {
                    Text(alias)
                        .font(AppFont.dongleRegular.of(size: isLandscapeOnIPhone ? 13 : 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 3) {
                        Text(pointText)
                            .font(AppFont.dongleRegular.of(size: 40))
                        Text(LocalizedStringKey.sdkAsset("point").toString())
                            .font(AppFont.dongleRegular.of(size: 32))
                    }
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 5)
            }
            .background(Color.orange.opacity(0.2))
            
            if disabled {
                HStack(spacing: 3) {
                    Spacer()
                    Image(sdkAsset: "warning")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 8, height: 8)
                    
                    Text(disableText ??  "")
                        .font(AppFont.dongleRegular.of(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .padding(.bottom, 2)
            }
        }
        .overlay(alignment: .trailing) {
            ZStack {
                Image(sdkAsset: disabled ? "disable_package_price" : "package_price")
                    .resizable()
                    .scaledToFit()
                Text(item.displayPrice)
                    .font(AppFont.dongleRegular.of(size: isLandscapeOnIPhone ? 18 : 22))
                    .foregroundColor(Color.white)
            }
            .foregroundColor(Color.yellow.opacity(0.9))
            .frame(maxWidth: fullWidth/3.8)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .background(Color.cyan.opacity(0.2))
        .padding(.horizontal, isLandscapeOnIPhone ? 4 : 8)
        .background(disabled ? Color.oliveTaupe : Color.brown.opacity(0.9))
        .cornerRadius(isLandscapeOnIPhone ? 8 : 12)
        .onTapGesture {
            if !disabled {
                action()
            }
        }
        .task {
            if isGuestUser {
                self.disabled = true
                self.disableText = LocalizedStringKey.sdkAsset("package_item_guest_disable").toString()
            } else if !item.isPurchasable {
                self.disabled = true
                self.disableText = LocalizedStringKey.sdkAsset("invalid_sku").toString()
            } else {
                self.disabled = false
            }
//            else {
//                let storefront = await Storefront.current
//                print("Country Code: \(String(describing: storefront?.countryCode))")
//                if let countryCode = storefront?.countryCode, countryCode == "VNM" {
//                    self.disabled = false
//                } else {
//                    self.disabled = true
//                    self.disableText = LocalizedStringKey.sdkAsset("package_item_notvn_disable").toString()
//                }
//            }
        }
    }
}


