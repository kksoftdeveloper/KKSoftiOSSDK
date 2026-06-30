import SwiftUI
import Combine

public struct GameServerView: View {
    @StateObject var viewModel: GameServerViewModel
    
    private var isShownCloseButton: Bool = false
    
    private var onClose: (() -> Void)? = nil
    private let onUpdatedGameServer: (Int?, String?) -> Void
    @SwiftUI.Environment(\.verticalSizeClass) var verticalSizeClass

    public init(
        authManager: AuthManager,
        isShownCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        onUpdatedGameServer: @escaping  (Int?, String?) -> Void
    ) {
        _viewModel = .init(wrappedValue: GameServerViewModel(authManager: authManager, onUpdatedGameServer: onUpdatedGameServer))
        self.onUpdatedGameServer = onUpdatedGameServer
        self.isShownCloseButton = isShownCloseButton
        self.onClose = onClose
    }
    
    init(viewModel: GameServerViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onUpdatedGameServer = { selectedGameServerId, gameUUID in
            
        }
    }
    
    public var body: some View {
        let isLandscape = verticalSizeClass == .compact
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let minValue = min(width, height, CGFloat((isPad ? 440 : Int.max)))
        let contentWidth = isLandscape ? minValue*0.9 : minValue
        
        content(width: contentWidth)
            .preferredColorScheme(.light)
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ZStack {
                            Color.clear
                                .ignoresSafeArea()
                            ProgressView(.sdkAsset("loading"))
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                                .background(Color.sdkPrimaryText)
                                .cornerRadius(10)
                                .shadow(radius: 10)
                        }
                    }
                }
            )
            .onAppear {
                viewModel.getGameServer()
            }
            .frame(width: contentWidth, height: contentWidth)
    }
    
    @ViewBuilder
    private func content(width: CGFloat) -> some View {
        if shouldShowMaintenanceState {
            maintenanceView()
        } else {
            serverGrid(width: width)
                .overlay(alignment: .bottom) {
                    primaryButton(width: width)
                }
                .overlay(alignment: .top) {
                    titleLabel()
                }
                .overlay(alignment: .topTrailing) {
                    closeButton()
                }
        }
    }

    private var shouldShowMaintenanceState: Bool {
        !viewModel.isLoading && viewModel.isMaintenance
    }

    @ViewBuilder
    private func maintenanceView() -> some View {
        let info = viewModel.getGamePublicInfo()
        ServerMaintenanceView(
            phoneNumber: info.phoneNumber,
            fanpage: info.fanpage,
            onUpdatedGameServer: self.onUpdatedGameServer
        )
    }

    private func serverGrid(width: CGFloat) -> some View {
        ZStack {
            Image(sdkAsset: "SquareBackground")
                .resizable()
                .frame(width: width)
                .aspectRatio(1, contentMode: .fit)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible())], spacing : 10) {
                    ForEach(viewModel.servers) { server in
                        ServerRow(
                            server: server,
                            isSelected: viewModel.selectedServer?.serverId == server.serverId
                        )
                        .onTapGesture {
                            handleServerSelection(server)
                        }
                    }
                }
            }
            .frame(width: width*0.8, height: width*0.65)
        }
    }

    private func primaryButton(width: CGFloat) -> some View {
        let primaryButtonWidth = width * 0.46
        return PrimaryButton(
            action: {
                viewModel.updateGameServer()
            },
            label: {
                Text(.sdkAsset("enter_game"))
                    .font(AppFont.poppinsBold.of(size: 14))
            },
            isDisabled: false
        )
        .frame(width: primaryButtonWidth, height: primaryButtonWidth * 0.35)
        .padding(.bottom, -width / 30)
    }

    private func titleLabel() -> some View {
        Text(.sdkAsset("select_server"))
            .font(AppFont.fsClanNarrowUltra.of(size: 14))
            .foregroundColor(.primaryText)
            .padding(.top, 30)
    }

    @ViewBuilder
    private func closeButton() -> some View {
        guard isShownCloseButton, let onClose else {
            return AnyView(EmptyView())
        }

        return AnyView(Button(action: {
            onClose()
        }) {
            Image(sdkAsset: "IconCross")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 53, height: 53)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8))
    }

    private func handleServerSelection(_ server: GameServerInfoResponse) {
        guard server.serverStatus == .online else { return }
        viewModel.select(server)
    }
}

final class MockGameServerViewModel: GameServerViewModel {
    init() {
        super.init(authManager: DefaultAuthManager.Builder().build(), onUpdatedGameServer: { a, b in
            
        })
        self.servers = [
            GameServerInfoResponse(serverId: 1, serverName: "Asia Server", serverClientId: nil,serverClientName: nil, serverStatus: .online),
            GameServerInfoResponse(serverId: 2, serverName: "Asia Server", serverClientId: nil,serverClientName: nil, serverStatus: .online),
            GameServerInfoResponse(serverId: 3, serverName: "Asia Server", serverClientId: nil,serverClientName: nil, serverStatus: .online),
            GameServerInfoResponse(serverId: 4, serverName: "Asia Server", serverClientId: nil,serverClientName: nil, serverStatus: .online),
            GameServerInfoResponse(serverId: 5, serverName: "Asia Server", serverClientId: nil,serverClientName: nil, serverStatus: .offline),
            GameServerInfoResponse(serverId: 6, serverName: "Asia Server", serverClientId: nil,serverClientName: nil, serverStatus: .online),
            GameServerInfoResponse(serverId: 7, serverName: "Asia Server", serverClientId: nil,serverClientName: nil, serverStatus: .offline),
            GameServerInfoResponse(serverId: 8, serverName: "Asia Server", serverClientId: nil,serverClientName: nil, serverStatus: .online)
        ]
        self.selectedServer = GameServerInfoResponse(serverId: 1, serverName: "Asia Server", serverClientId: nil,serverClientName: nil, serverStatus: .online)
    }
}

#Preview {
    GameServerView(viewModel: MockGameServerViewModel())
}

#Preview {
    GameServerView(authManager: DefaultAuthManager.Builder().build(), onUpdatedGameServer: {a, b in
    })
}
