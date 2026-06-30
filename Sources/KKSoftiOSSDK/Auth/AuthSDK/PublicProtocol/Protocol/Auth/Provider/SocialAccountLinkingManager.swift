//
//  LinkAccountManager.swift
//  AuthSDK
//
//  Created by X on 4/21/25.
//

import Foundation
import Combine

public protocol SocialAccountLinkingManager {
    func googleAccountLinker() -> AnyPublisher<AuthSessionResponse, any Error>
    func facebookAccountLinker() -> AnyPublisher<AuthSessionResponse, any Error>
}

