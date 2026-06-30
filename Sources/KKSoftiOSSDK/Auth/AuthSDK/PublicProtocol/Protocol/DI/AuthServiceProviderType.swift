//
//  DependencyProvider.swift
//  AuthSDK
//

import Foundation

protocol AuthServiceProviderType {
    var appVersion: String { get }
    
    var osVersion: String { get }
    
    var authManager: AuthManager { get }
    
    var authAPIClient: AuthAPIClient { get }
    
    var initialializer: Initialializer { get }
    
    var emailPasswordLoginManager: UsernamePasswordLoginManager { get }
    
    var phonePasswordLoginManager: UsernamePasswordLoginManager { get }
    
    var facebookLoginManager: SocialLoginManager { get }
    
    var googleLoginManager: SocialLoginManager { get }
    
    var guestLoginManager: GuestLoginManager { get }
    
    var otpAuthManager: OTPAuthManager { get }
    
    var signupManager: SignupManager { get }
    
    var gameServerInfoManager: GameServerInfoManager { get }
    
    var refreshTokenManager: RefreshTokenManager { get }
    
    var deactivateManager: DeactivateManager { get }
}
