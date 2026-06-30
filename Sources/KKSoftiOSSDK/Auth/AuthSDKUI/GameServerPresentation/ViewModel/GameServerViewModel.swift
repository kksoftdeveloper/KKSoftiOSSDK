import Foundation
import Combine
import SwiftUI

@MainActor
class GameServerViewModel: OpenViewModel {
    
    @Published var servers: [GameServerInfoResponse] = []
    @Published private(set) var errorMessage: String?
    
    @Published var selectedServer: GameServerInfoResponse?
    
    @Published var isMaintenance = false
    
    private var authManager: AuthManager
    private let onUpdatedGameServer: (Int?, String?) -> Void
    
    init(authManager: AuthManager, onUpdatedGameServer: @escaping (Int?, String?) -> Void) {
        self.authManager = authManager
        self.onUpdatedGameServer = onUpdatedGameServer
    }
    
    func getGameServer() {
        isLoading = true
        authManager.getGameServerLists()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.isLoading = false
                    self.isMaintenance = false
                    debugPrint("❌ get-game-server list failed:", (error as? AuthErrorResponse)?.message ?? error.localizedDescription)
                    self.errorMessage = (error as? AuthErrorResponse)?.message ?? LocalizedStringKey.sdkAsset("unknown_error_message").toString()

                case .finished:
                    break
                }
            }, receiveValue: { gameServerList in
                self.isLoading = false
                self.servers = gameServerList
                self.isMaintenance = gameServerList.isEmpty
                debugPrint("✅ get-game-server list success:", gameServerList)
            })
            .store(in: &cancellables)
    }
    
    func select(_ server: GameServerInfoResponse) {
        if self.selectedServer?.serverId == server.serverId {
            selectedServer = nil
        } else {
            selectedServer = server
        }
    }
    
    func updateGameServer() {
        if let selectedServer = self.selectedServer {
            isLoading = true
            authManager.updateGameServer(selectedGameServer: selectedServer)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        self.isLoading = false
                        debugPrint("❌ update-game-server list failed:", (error as? AuthErrorResponse)?.message ?? error.localizedDescription)
                        self.errorMessage = (error as? AuthErrorResponse)?.message ?? LocalizedStringKey.sdkAsset("unknown_error_message").toString()
                        
                    case .finished:
                        break
                    }
                }, receiveValue: { gameUUID in
                    self.isLoading = false
                    debugPrint("✅ update-game-server list success:", gameUUID)
                    self.onUpdatedGameServer(selectedServer.serverId, gameUUID)
                    
                })
                .store(in: &cancellables)
        }
    }
    
    func getGamePublicInfo() -> GamePublicInfoResponse {
        return authManager.getGamePublicInfo()
    }
}
