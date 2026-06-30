import SwiftUI

public struct ForceUpdateView: View {
    let appStoreId: String
    
    @StateObject var viewModel: ForceUpdateViewModel
    
//    private let onSubmit: () -> Void
    
    public init(/*onSubmit: @escaping () -> Void = { }*/
        appStoreId: String
    ) {
        _viewModel = .init(wrappedValue: ForceUpdateViewModel())
//        self.onSubmit = onSubmit
        self.appStoreId = appStoreId
    }
    
    public var body: some View {
        content
            .preferredColorScheme(.light)
    }
    
    
    @ViewBuilder
    private var content: some View {
        SquareContainer(shouldShowCross: false, onCloseClick: {}, content: {
            VStack {
                Text(.sdkAsset("force_update_title"))
                    .font(AppFont.fsClanNarrowUltra.of(size: 16))
                    .foregroundColor(.primaryText)
                    .padding(.vertical, 15)
                Text(.sdkAsset("force_update_subtitle"))
                    .font(AppFont.poppinsLight.of(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primaryText)
                    .padding(.horizontal, 48)
            }
        }, footer: {
            PrimaryButton(
                action: {
                    if let url = URL(string: "https://apps.apple.com/app/" + appStoreId) {
                                       UIApplication.shared.open(url)
                                   }
                },
                label: {
                    Text(.sdkAsset("update"))
                },
                isDisabled: false
            )
        })
    }
}

#Preview {
//    ForceUpdateView(let: "123")
}
