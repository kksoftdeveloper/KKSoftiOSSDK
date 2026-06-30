import SwiftUI
import StoreKit

public struct PackageListView: View {
    @StateObject var viewModel: PackageListViewModel
    let onCloseClick: () -> Void
    //    let auth: AuthSessionResponse
    @State private var lastTrackedPopupId: UUID?
    
    @SwiftUI.Environment(\.verticalSizeClass) var verticalSizeClass
    
    public init(
        onCloseClick: @escaping () -> Void,
        //        authManager: AuthManager,
        //        auth: AuthSessionResponse,
        packageName: String,
        gameId: Int,
        
        deviceId: String,
        osVersion: String,
        
        accessToken: String,
        refreshToken: String,
        phoneNumber: String,
        
        appVersion: String,
        
        serverId: Int,
        gameUUID: String,
        isGuestUser: Bool = false,
        
    ) {
        //        let rawId = authService.authManager.getServerId() ?? 0
        //        let serId = (rawId > 0) ? rawId : 22
        
        let paymentbuilder = DefaultPaymentManager.Builder()
            .setDeviceId(deviceId)
            .setOSVersion(osVersion)
            .setIsGuestUser(isGuestUser)
        
            .setAccessToken(accessToken)
            .setRefreshToken(refreshToken)
            .setPhoneNumber(phoneNumber)
        
            .setAppVersion(appVersion)
            .setPackageName(packageName)
        
            .setGameId(gameId)
            .setServerId(serverId)
            .setGameUUID(gameUUID)
        
        _viewModel = .init(
            wrappedValue: PackageListViewModel(
                paymentManager: paymentbuilder.build()
            )
        )
        
        self.onCloseClick = onCloseClick
    }
    
    public var body: some View {
        let isLandscape = verticalSizeClass == .compact
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let minValue = min(width, height, CGFloat((isPad ? 440 : Int.max)))
        let contentWidth = isLandscape ? minValue*0.88*0.9 : minValue
        
        content(width: contentWidth)
            .popup(item: $viewModel.paymentPopUp, backgroundOpacity: 0.4, content: { item, dismiss in
                PopUpView(
                    title: item.title,
                    description: item.description,
                    submitButtonTitle: item.buttonTitle,
                    product: item.product,
                    orderId: item.orderId,
                    onClose: {
                        viewModel.paymentPopUp = nil
                    }, onSubmit: {
                        viewModel.paymentPopUp = nil
                    }
                )
                .onAppear {
                    trackPopupIfNeeded(item)
                }
            })
            .onAppear {
                FontLoader.loadAllFonts()
                viewModel.loadGamePackages()
                PaymentTracking.logIAPStart(
                    gameUUID: viewModel.paymentManager?.gameUUID,
                    characterId: viewModel.paymentManager?.characterId,
                    serverId: viewModel.paymentManager?.serverId,
                    serverName: viewModel.paymentManager?.gameServerName
                )
                NotificationCenter.default.post(
                    name: NSNotification.Name(NotificationKeys.IAP_START),
                    object:  [
                        "game_uuid": viewModel.paymentManager?.gameUUID,
                        "character_id": viewModel.paymentManager?.characterId,
                        "server_id": viewModel.paymentManager?.gameServerId,
                        "server_name": viewModel.paymentManager?.gameServerName
                    ]
                )
            }
    }
    
    private let columns = [
        GridItem(.flexible())
    ]
    
    public func content(width: CGFloat) -> some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                ZStack {
                    Image(sdkAsset: "PackageFrame")
                        .resizable()
                        .scaledToFit()
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing : 10) {
                            ForEach(Array(viewModel.products.enumerated()), id: \.element.id) { index, item in
                                PackageItemView(item: item, isGuestUser: viewModel.paymentManager?.guestUser ?? false) {
                                    viewModel.purchaseProduct(item)
                                }
                                .onAppear {
                                    if index == viewModel.products.count - 1 {
                                        viewModel.loadGamePackages()
                                    }
                                }
                            }
                        }
                    }
                    .refreshable {
                        viewModel.loadGamePackages(reset: true)
                    }
                    .frame(width: width*0.82, height: width*0.75)
                    
                    //                    ScrollView {
                    //                        LazyVGrid(columns: columns, spacing : 10) {
                    //                            ForEach(
                    //                                viewModel.products.indices,
                    //                                id: \.self
                    //                            ) { index in
                    //                                if let product = viewModel.products[index] as? Product {
                    //                                    PackageItemView(product: product) {
                    //                                        viewModel.purchaseProduct(product)
                    //                                    }
                    //                                }
                    //                            }
                    //                        }
                    //                    }
                    //                    .frame(width: width*0.82, height: width*0.75)
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.2)
                    }
                }
                .frame(width: width)
                .overlay(alignment: .top) {
                    Text(.sdkAsset("package_list_title"))
                        .font(
                            AppFont.fsClanNarrowUltra
                                .of(size: verticalSizeClass == .regular  ? 14 : 10)
                        )
                        .foregroundColor(.primaryText)
                        .padding(.top, verticalSizeClass == .regular ? 38 : 28)
                }
                .overlay(
                    alignment: .topTrailing,
                    content: {
                        let closeButtonSize = width * 0.13 * (verticalSizeClass == .regular ? 1 : 0.8)
                        Button(action: onCloseClick) {
                            Image(sdkAsset: "IconCross")
                                .resizable()
                                .frame(
                                    width: closeButtonSize,
                                    height: closeButtonSize
                                )
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 20)
                    })
                Spacer()
            }
            Spacer()
        }
    }
    
    private func trackPopupIfNeeded(_ popup: PaymentPopUp) {
        guard lastTrackedPopupId != popup.id, let product = popup.product else { return }
        lastTrackedPopupId = popup.id
        let gameUUID = viewModel.paymentManager?.gameUUID
        let characterId = viewModel.paymentManager?.characterId
        let serverId = viewModel.paymentManager?.serverId
        let serverName = viewModel.paymentManager?.gameServerName
        switch popup.kind {
        case .success(let orderId):
            PaymentTracking.logIAPSuccess(product: product, orderId: orderId ?? "", gameUUID: gameUUID, characterId: characterId, serverId: serverId, serverName: serverName)
        case .failure(let reason, let error):
            PaymentTracking.logIAPFailure(product: product, reason: reason, error: error, gameUUID: gameUUID, characterId: characterId, serverId: serverId, serverName: serverName)
        }
    }
}

//#Preview {
//    PackageListView(
//        viewModel: .init(
//            paymentManager: try? DefaultPaymentManager.Builder().build()
//        ),
//        onCloseClick: {
//        })
//}
