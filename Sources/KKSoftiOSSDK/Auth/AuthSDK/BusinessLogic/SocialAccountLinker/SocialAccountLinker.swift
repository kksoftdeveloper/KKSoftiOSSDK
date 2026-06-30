import Foundation
import Combine
import FBSDKCoreKit
import FBSDKLoginKit
import UIKit

import GoogleSignIn

final class SocialAccountLinker: SocialAccountLinkingManager, DeviceIdentifiable, SDKInfo, SignupAnalytics {
  
    var authAPIClient: AuthAPIClient
    var gameInfoStorage: GameInfoStorage
    var gamePlayerStorage: GamePlayerStorage
    var sessionManager: SessionManager
    var signature: Signature
    var cancellables = Set<AnyCancellable>()
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    lazy var fbLoginManager: LoginManager = LoginManager()
    
    init(authAPIClient: AuthAPIClient,
         sessionManager: SessionManager = KeyChainSessionManager(),
         gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage(),
         signature: Signature = SHA256Signature(),
         gamePlayerStorage: GamePlayerStorage = GamePlayerKeychainStorage()
    ) {
        self.authAPIClient = authAPIClient
        self.sessionManager = sessionManager
        self.gameInfoStorage = gameInfoStorage
        self.signature = signature
        self.gamePlayerStorage = gamePlayerStorage
    }
}

struct SocialLinkAccountRequestBody: Encodable {
    let token: String
    let type: String
    let deviceId: String
    let appVersion: String
    let platform: String
    let sdkVersion: String
    let gameId: Int
    let serverId: Int
    let sign: String
    
    private enum CodingKeys: String, CodingKey {
        case token
        case type
        case deviceId
        case appVersion
        case platform
        case sdkVersion
        case gameId
        case serverId
        case sign
    }
}
