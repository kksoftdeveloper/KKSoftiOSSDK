//
//  GamePlayerProtocol.swift
//  PaymentSDK
//
//  Created by X on 5/31/25.
//

import Foundation
import Combine

public protocol GamePlayerManager {
    func deactiveAccount() -> AnyPublisher<DatalessOutput, PaymentError>
}
