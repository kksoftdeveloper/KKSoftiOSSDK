import SwiftUI

public struct TokenExpirationView: View {
    @StateObject var viewModel: TokenExpirationViewModel
    
    private let onConfirm: () -> Void
    
    public init(onConfirm: @escaping () -> Void = { }) {
        _viewModel = .init(wrappedValue: TokenExpirationViewModel())
        self.onConfirm = onConfirm
    }
    
    public var body: some View {
        content
            .preferredColorScheme(.light)
    }
    
    @ViewBuilder
    private var content: some View {
        SquareContainer(
            shouldShowCross: false,
            onCloseClick: {
                
            },
            content: {
                VStack {
                    Text(.sdkAsset("token_expiration_confirm_title"))
                        .font(AppFont.fsClanNarrowUltra.of(size: 16))
                        .foregroundColor(.primaryText)
                        .padding(.vertical, 15)
                    Text(.sdkAsset("token_expiration_description"))
                        .font(AppFont.poppinsRegular.of(size: 12))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryText)
                        .padding(.horizontal, 30)
                }
            }, footer: {
                PrimaryButton(
                    action: {
                        onConfirm()
                    },
                    label: {
                        Text(.sdkAsset("confirm"))
                    },
                    isDisabled: false
                )
            })
    }
}

#Preview {
    TokenExpirationView() {}
}
