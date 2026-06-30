//
//  RefreshTokenManager.swift
//  AuthSDK
//

import Foundation
import Combine

public protocol RefreshTokenManager {
    
    func refreshToken() -> AnyPublisher<AuthSessionResponse, Error>
}
