//
//  DefaultDependencyProvider.swift
//  AuthSDK
//

import Foundation

public struct AuthServiceProvider: AuthServiceProviderType {
    var appVersion: String
    
    var osVersion: String
    
    var authAPIClient: any AuthAPIClient
    
    var initialializer: any Initialializer
    
    var emailPasswordLoginManager: any UsernamePasswordLoginManager
    
    var phonePasswordLoginManager: any UsernamePasswordLoginManager
    
    var facebookLoginManager: any SocialLoginManager
    
    var googleLoginManager: any SocialLoginManager
    
    var appleLoginManager: any SocialLoginManager
    
    var guestLoginManager: any GuestLoginManager
    
    var otpAuthManager: any OTPAuthManager
    
    var gameServerInfoManager: any GameServerInfoManager
    
    var refreshTokenManager: any RefreshTokenManager
    
    var linkAccountManager: any SocialAccountLinkingManager
    
    var forgetPasswordManager: any ForgetPasswordManager
    
    var signupManager: any SignupManager
    
    var deactivateManager: any DeactivateManager
    
    public var authManager: any AuthManager
    
    // Private init to enforce builder usage
    private init(builder: Builder) {
        self.appVersion = builder.appVersion
        self.osVersion = builder.osVersion
        
        Environment.current = (Bundle.main.infoDictionary?[ "APP_ENV" ] as? String)?.lowercased() == "staging" ? Environment.staging : Environment.production
        
        self.authAPIClient = builder.authAPIClient
        
        self.initialializer = builder.initialializer ?? DefaultInitializer(authAPIClient: authAPIClient)
        
        self.emailPasswordLoginManager = builder.emailPasswordLoginManager ?? EmailPasswordLoginManager(authAPIClient: authAPIClient)
        
        self.phonePasswordLoginManager = builder.phonePasswordLoginManager ?? PhonePasswordLoginManager(authAPIClient: authAPIClient)
        
        self.googleLoginManager = builder.googleLoginManager ?? GoogleLoginManager(authAPIClient: authAPIClient)
        
        self.facebookLoginManager = builder.facebookLoginManager ?? FacebookLoginManager(authAPIClient: authAPIClient)
        
        self.appleLoginManager = builder.appleLoginManager ?? AppleLoginManager(authAPIClient: authAPIClient)
        
        self.guestLoginManager = builder.guestLoginManager ?? DefaultGuestLoginManager(authAPIClient: authAPIClient)
        
        self.otpAuthManager = builder.otpAuthManager ?? DefaultOTPAuthManager(authAPIClient: authAPIClient)
        
        self.gameServerInfoManager = builder.gameServerInfoManager ?? DefaultGameServerInfoManager(authAPIClient: authAPIClient)
        
        self.signupManager = builder.signupManager ?? PhoneSignupManager(authAPIClient: authAPIClient)
        
        self.linkAccountManager = builder.linkAccountManager ?? SocialAccountLinker(authAPIClient: authAPIClient)
        
        self.forgetPasswordManager = builder.forgetPasswordManager ?? DefaultForgetPasswordManager(authAPIClient: authAPIClient)
        
        self.refreshTokenManager = builder.refreshTokenManager ?? DefaultRefreshTokenManager(authAPIClient: authAPIClient)
        
        self.deactivateManager = builder.deactivateManager ?? DefaultDeactivateManager(authAPIClient: authAPIClient)
        
        self.authManager = builder.authManager ??
            DefaultAuthManager
                .Builder()
                .setAppVersion(appVersion)
                .setOSVersion(osVersion)
                .setGoogleLoginManager(googleLoginManager)
                .setFacebookLoginManager(facebookLoginManager)
                .setPhonePasswordLoginManager(phonePasswordLoginManager)
                .setEmailPasswordLoginManager(emailPasswordLoginManager)
                .setGuestLoginManager(guestLoginManager)
                .setOTPAuthManager(otpAuthManager)
                .setInitializer(initialializer)
                .setSignupManager(signupManager)
                .setRefreshTokenManager(refreshTokenManager)
                .setLinkAccountManager(linkAccountManager)
                .setForgetPasswordManager(forgetPasswordManager)
                .setDeactivateManager(deactivateManager)
                .build()
    }
    
    // Nested Builder Class
    public class Builder {
        var appVersion: String = ""
        var osVersion: String = ""
        
        // Default implementations (can be overridden)
        var authAPIClient: AuthAPIClient = DefaultAuthAPIClient.Builder().build()
        
        var initialializer: Initialializer?
        
        var googleLoginManager: SocialLoginManager?
        
        var facebookLoginManager: SocialLoginManager?
        
        var appleLoginManager: SocialLoginManager?
        
        var emailPasswordLoginManager: UsernamePasswordLoginManager?
        
        var phonePasswordLoginManager: UsernamePasswordLoginManager?
        
        var guestLoginManager: GuestLoginManager?
        
        var otpAuthManager: OTPAuthManager?
        
        var gameServerInfoManager: GameServerInfoManager?
        
        var signupManager: SignupManager?
        
        var refreshTokenManager: RefreshTokenManager?
        
        var linkAccountManager: SocialAccountLinkingManager?
        
        var forgetPasswordManager: ForgetPasswordManager?
        
        var deactivateManager: DeactivateManager?
        
        var authManager: AuthManager?
        
        public init() { }
        
        public func setAppVersion(_ appVersion: String) -> Builder {
            self.appVersion = appVersion
            return self
        }
        
        public func setOSVersion(_ osVersion: String) -> Builder {
            self.osVersion = osVersion
            return self
        }
        
        public func setGoogleLoginManager(_ manager: SocialLoginManager) -> Builder {
            self.googleLoginManager = manager
            return self
        }
        
        public func setFacebookLoginManager(_ manager: SocialLoginManager) -> Builder {
            self.facebookLoginManager = manager
            return self
        }
        
        public func setAppleLoginManager(_ manager: SocialLoginManager) -> Builder {
            self.appleLoginManager = manager
            return self
        }
        
        public func setEmailPasswordLoginManager(_ manager: UsernamePasswordLoginManager) -> Builder {
            self.emailPasswordLoginManager = manager
            return self
        }
        
        public func setPhonePasswordLoginManager(_ manager: UsernamePasswordLoginManager) -> Builder {
            self.phonePasswordLoginManager = manager
            return self
        }
        
        public func setGuestLoginManager(_ manager: GuestLoginManager) -> Builder {
            self.guestLoginManager = manager
            return self
        }
        
        public func setOTPAuthManager(_ manager: OTPAuthManager) -> Builder {
            self.otpAuthManager = manager
            return self
        }
        
        public func setInitializer(_ initializer: Initialializer) -> Builder {
            self.initialializer = initializer
            return self
        }
        
        public func setGameServerInfoManager(_ gameServerInfoManager: GameServerInfoManager) -> Builder {
            self.gameServerInfoManager = gameServerInfoManager
            return self
        }
        
        public func setSignupManager(_ signupManager: SignupManager) -> Builder {
            self.signupManager = signupManager
            return self
        }
        
        public func setLinkAccountManager(_ linkAccountManager: SocialAccountLinkingManager) -> Builder {
            self.linkAccountManager = linkAccountManager
            return self
        }
        
        public func setForgetPasswordManager(_ forgetPasswordManager: ForgetPasswordManager) -> Builder {
            self.forgetPasswordManager = forgetPasswordManager
            return self
        }
        
        public func setRefreshTokenManager(_ refreshTokenManager: RefreshTokenManager) -> Builder {
            self.refreshTokenManager = refreshTokenManager
            return self
        }
        
        public func setDeactivateManager(_ deactivateManager: DeactivateManager) -> Builder {
            self.deactivateManager = deactivateManager
            return self
        }
        
        public func build() -> AuthServiceProvider {
            // Build dependent objects
            let emailPasswordManager = emailPasswordLoginManager ?? EmailPasswordLoginManager(authAPIClient: authAPIClient)
            
            let phonePasswordManager = phonePasswordLoginManager ?? PhonePasswordLoginManager(authAPIClient: authAPIClient)
            
            let googleLoginManager = googleLoginManager ?? GoogleLoginManager(authAPIClient: authAPIClient)
            
            let appleLoginManager = appleLoginManager ?? AppleLoginManager(authAPIClient: authAPIClient)
            
            let facebookLoginManager = facebookLoginManager ?? FacebookLoginManager(authAPIClient: authAPIClient)
            
            let otpManager = otpAuthManager ?? DefaultOTPAuthManager(authAPIClient: authAPIClient)
            
            let guestLoginManager = guestLoginManager ?? DefaultGuestLoginManager(authAPIClient: authAPIClient)
            
            let initialializer = initialializer ?? DefaultInitializer(authAPIClient: authAPIClient)
            
            let gameServerInfoManager = gameServerInfoManager ?? DefaultGameServerInfoManager(authAPIClient: authAPIClient)
            
            let signupManager = signupManager ?? PhoneSignupManager(authAPIClient: authAPIClient)
            
            let linkAccountManager = linkAccountManager ?? SocialAccountLinker (authAPIClient: authAPIClient)
            
            let forgetPasswordManager = forgetPasswordManager ?? DefaultForgetPasswordManager(authAPIClient: authAPIClient)
            
            let refreshTokenManager = refreshTokenManager ?? DefaultRefreshTokenManager(authAPIClient: authAPIClient)
            
            let deactivateManager = deactivateManager ?? DefaultDeactivateManager(authAPIClient: authAPIClient)
            
            let finalAuthManager: AuthManager = DefaultAuthManager
                .Builder()
                .setAppVersion(appVersion)
                .setOSVersion(osVersion)
                .setGoogleLoginManager(googleLoginManager)
                .setFacebookLoginManager(facebookLoginManager)
                .setAppleLoginManager(appleLoginManager)
                .setOTPAuthManager(otpManager)
                .setEmailPasswordLoginManager(emailPasswordManager)
                .setPhonePasswordLoginManager(phonePasswordManager)
                .setGuestLoginManager(guestLoginManager)
                .setInitializer(initialializer)
                .setGameServerInfoManager(gameServerInfoManager)
                .setSignupManager(signupManager)
                .setLinkAccountManager(linkAccountManager)
                .setForgetPasswordManager(forgetPasswordManager)
                .setRefreshTokenManager(refreshTokenManager)
                .setDeactivateManager(deactivateManager)
                .build()
            
            // Construct the AuthServiceProvider
            return AuthServiceProvider(builder: self)
                .setting(\.emailPasswordLoginManager, emailPasswordManager)
                .setting(\.phonePasswordLoginManager, phonePasswordManager)
                .setting(\.otpAuthManager, otpManager)
                .setting(\.googleLoginManager, googleLoginManager)
                .setting(\.facebookLoginManager, facebookLoginManager)
                .setting(\.guestLoginManager, guestLoginManager)
                .setting(\.authManager, finalAuthManager)
                .setting(\.initialializer, initialializer)
                .setting(\.gameServerInfoManager, gameServerInfoManager)
                .setting(\.signupManager, signupManager)
                .setting(\.linkAccountManager, linkAccountManager)
                .setting(\.forgetPasswordManager, forgetPasswordManager)
                .setting(\.refreshTokenManager, refreshTokenManager)
                .setting(\.deactivateManager, deactivateManager)
        }
    }
}

// Helper to set private properties after init
private extension AuthServiceProvider {
    func setting<T>(_ keyPath: WritableKeyPath<AuthServiceProvider, T>, _ value: T) -> AuthServiceProvider {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}
