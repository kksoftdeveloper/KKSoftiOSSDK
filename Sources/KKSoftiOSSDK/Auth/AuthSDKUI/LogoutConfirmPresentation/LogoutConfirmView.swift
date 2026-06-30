import SwiftUI

public struct LogoutConfirmView: View {
    @StateObject var viewModel: LogoutConfirmViewModel
    
    private let onClose: () -> Void
    private let onConfirm: () -> Void
    
    public init(onClose: @escaping () -> Void = { }, onConfirm: @escaping () -> Void = { }) {
        _viewModel = .init(wrappedValue: LogoutConfirmViewModel())
        self.onClose = onClose
        self.onConfirm = onConfirm
    }
    
    public var body: some View {
        content
            .preferredColorScheme(.light)
    }
    
    @ViewBuilder
    private var content: some View {
        SquareContainer(onCloseClick: {
            onClose()
        }, content: {
            VStack {
                Text(.sdkAsset("logout_confirm_title"))
                    .font(AppFont.fsClanNarrowUltra.of(size: 16))
                    .foregroundColor(.primaryText)
                    .padding(.vertical, 15)
                Text(.sdkAsset("logout_confirm_description"))
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

//#Preview {
//    ForceUpdateView()
//}
