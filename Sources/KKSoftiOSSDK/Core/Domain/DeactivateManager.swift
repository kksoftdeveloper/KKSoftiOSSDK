//
//  DeactivateManager.swift
//  KKSoftiOSSDK
//
//  Created by KKSOFT on 10/6/26.
//

import Foundation
import Combine

public protocol DeactivateManager {
    func deactivateAccount() -> AnyPublisher<DatalessServerResponse, Error>
}
