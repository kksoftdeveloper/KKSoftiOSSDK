//
//  Deactivate.swift
//  AuthSDK
//
//  Created by X on 6/2/25.
//

import Foundation
import Combine

final class DefaultDeactivateManager: DeactivateManager, DeviceIdentifiable, SDKInfo, DeactivateProperties {
    
    private var authAPIClient: AuthAPIClient
    private var sessionManager: SessionManager
    private var gamePlayerStorage: GamePlayerStorage
    private var gameInfoStorage: GameInfoStorage
    public var deviceSecretKey: String
    
    init(authAPIClient: AuthAPIClient,
         sessionManager: SessionManager = KeyChainSessionManager(),
         gamePlayerStorage: GamePlayerStorage = GamePlayerKeychainStorage(),
         gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage()
    ) {
        self.authAPIClient = authAPIClient
        self.sessionManager = sessionManager
        self.gamePlayerStorage = gamePlayerStorage
        self.gameInfoStorage = gameInfoStorage
        deviceSecretKey = Environment.deviceSecretKey
    }
    
    func deactivateAccount() -> AnyPublisher<DatalessServerResponse, any Error> {
        guard let _ = try? sessionManager.getSession()?.accessToken else {
            BaseAnalytics.track(event: self.deactivateAccount, properties: [self.failure : AuthErrorResponse.unauthenticated().message])
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
//        let header = ["Authorization": "Bearer \(accessToken)"]
//        let header =
        return authAPIClient.deactivateAccount(header: [:])
            .tryMap { resDTO in
                try self.sessionManager.clear()
                try self.gamePlayerStorage.clear()
                self.gameInfoStorage.clear()
                return resDTO.toModel().toResponse()
            }
            .eraseToAnyPublisher()
    }
}
