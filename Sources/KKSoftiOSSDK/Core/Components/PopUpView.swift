import SwiftUI
import StoreKit

public struct PopUpView: View {
    
    private let title: String
    private let description: String
    private let submitButtonTitle: String
    private let product: Product?
    private let orderId: String?
    
    private let onClose: () -> Void
    private let onSubmit: () -> Void
    private let isShowClose: Bool
    
    public init(
        title: String,
        description: String,
        submitButtonTitle: String,
        product: Product?,
        orderId: String?,
        onClose: @escaping () -> Void = { },
        onSubmit: @escaping () -> Void = { },
        isShowClose: Bool = false
    ) {
        self.title = title
        self.description = description
        self.submitButtonTitle = submitButtonTitle
        self.product = product
        self.orderId = orderId
        self.onClose = onClose
        self.onSubmit = onSubmit
        self.isShowClose = isShowClose
    }
    
    public var body: some View {
        content
            .preferredColorScheme(.light)
            .onAppear {
                if self.product != nil && self.orderId != nil {
//                    PaymentTracking.logIAPSuccess(product: self.product!, orderId: self.orderId!)
                }
            }
    }
    
    
    @ViewBuilder
    private var content: some View {
        SquareContainer(
            shouldShowCross: isShowClose,
            onCloseClick: {
            onClose()
        }, content: {
            VStack {
                Text(title)
                    .font(AppFont.fsClanNarrowUltra.of(size: 16))
                    .foregroundColor(.primaryText)
                    .padding(.vertical, 15)
                Text(description)
                    .font(AppFont.poppinsRegular.of(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primaryText)
                    .padding(.horizontal, 64)
            }
        }, footer: {
            PrimaryButton(
                action: {
                    onSubmit()
                },
                label: {
                    Text(submitButtonTitle)
                        .foregroundColor(.white)
                },
                isDisabled: false
            )
            .frame(width: 144, height: 36)
        })
    }
}

//#Preview {
//    PopUpView(title: "Thanh toán thành công!", description: "Chúc mừng đại hiệp đã mua thành công gói vật phẩm ABC. Vật phẩm đã được gởi vào túi hành lí", submitButtonTitle: "Đóng", onClose: {}, onSubmit: {})
//}
