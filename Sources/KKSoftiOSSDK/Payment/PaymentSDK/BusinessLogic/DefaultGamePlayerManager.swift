//
//  GamePlayer.swift
//  PaymentSDK
//
//  Created by X on 5/31/25.
//

import Foundation
import Combine

final class DefaultGamePlayerManager: GamePlayerManager {
    
    private var paymentAPIClient: PaymentAPIClient
    private var sessionManager: SessionManager
    
    init(paymentAPIClient: PaymentAPIClient,
         sessionManager: SessionManager = KeyChainSessionManager()) {
        self.paymentAPIClient = paymentAPIClient
        self.sessionManager = sessionManager
    }
    
    func deactiveAccount() -> AnyPublisher<DatalessOutput, PaymentError> {
        do {
            var header: [String: Any] = [:]
            let accessToken = try sessionManager.getSession()?.accessToken
            header["Authorization"] = "Bearer \(String(describing: accessToken))"
            
            return self.paymentAPIClient.deactiveAccount(header: header)
                .tryMap { resDTO in
                    resDTO.toModel().toOutput()
                }
                .mapError { error in
                    return error as? PaymentError ?? PaymentError.purchaseFailed(reason: error.localizedDescription)
                }
                .eraseToAnyPublisher()
            
        } catch {
            return Fail(error: PaymentError.unauthenticated()).eraseToAnyPublisher()
        }
    }
}
