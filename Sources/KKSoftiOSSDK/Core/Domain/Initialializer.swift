//
//  Initialializer.swift
//  AuthSDK
//

import Foundation
import Combine



public protocol Initialializer {
    func initSDK(packageName: String, appVersion: String, serverId: Int) -> AnyPublisher<AuthInitResponse, Error>
}

public protocol PaymentInitialializer {
    func initSDK() -> AnyPublisher<DatalessOutput, Error>
}

