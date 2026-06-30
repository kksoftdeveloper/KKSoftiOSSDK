//
//  DefaultPaymentManager.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation
import Combine
import StoreKit

public final class DefaultPaymentManager: PaymentManager, SDKInfo, IAPAnalytics {
    
    public var accessToken: String
    
    public var refreshToken: String
    
    public var deviceId: String
    
    public var osVersion: String
    
    public var packageName: String
    
    public var appVersion: String
    
    public var gameId: Int
    
    public var serverId: Int
    
    public var gameServerId: String
    
    public var gameServerName: String
    
    public var characterId: String
    
    public var gameUUID: String
    
    public var phoneNumber: String
    
    public var guestUser: Bool
    
    private var initializer: PaymentInitialializer?
    
    private var paymentGateway: PaymentGateway?
    
    private var gamePlayerManager: GamePlayerManager?
    
    private var cancellables: Set<AnyCancellable>
    
    public func initSDK() -> AnyPublisher<DatalessOutput, any Error> {
        do {
            guard let initializer = self.initializer else {
                throw PaymentError.unknownError()
            }
            return initializer.initSDK()
        
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    private init(
        builder: Builder,
        cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    ) {
        self.accessToken = builder.accessToken
        self.refreshToken = builder.refreshToken
        
        self.deviceId = builder.deviceId
        self.osVersion = builder.osVersion
        
        self.packageName = builder.packageName
        self.appVersion = builder.appVersion
        
        self.gameId = builder.gameId
        self.gameServerId = builder.gameServerId
        self.gameServerName = builder.gameServerName
        self.characterId = builder.characterId
        self.gameUUID = builder.gameUUID
        self.phoneNumber = builder.phoneNumber
        self.guestUser = builder.guestUser
        self.paymentGateway = builder.paymentGateway
        self.gamePlayerManager = builder.gamePlayerManager
        
        self.cancellables = cancellables
        self.serverId = builder.serverId
    }
    
    public class Builder {
        var paymentAPIClient: PaymentAPIClient = DefaultPaymentAPIClient.Builder().build()
        private let authSDKSessionManager = KeyChainSessionManager()
        private let authSDKGameInfo = DefaultGameInfoStorage()
        
        // Session
        var accessToken: String = ""
        var refreshToken: String = ""
        
        // DeviceInfo
        var deviceId: String = ""
        var osVersion: String = ""
        
        // AppInfo
        var packageName: String = ""
        var appVersion: String = ""
        
        // GameInfo
        var gameId: Int = 1
        var serverId: Int = 1
        var gameServerId: String = ""
        var gameServerName: String = ""
        var characterId: String = ""
        var gameUUID: String = ""
        
        // GamePlayerInfo
        var phoneNumber: String = ""
        var guestUser: Bool = false
        
        var initializer: PaymentInitialializer?
        var paymentGateway: PaymentGateway?
        var gamePlayerManager: GamePlayerManager?
        
        public init() {
            self.sessionManager = KeyChainSessionManager()
            self.deviceInfo = DeviceInfoKeychainStorage()
            self.appInfo = DefaultAppInfoStorage()
            self.gameInfo = DefaultGameInfoStorage()
            self.gamePlayerInfo = GamePlayerKeychainStorage()
            self.paymentGateway = ApplePaymentGateway(paymentAPIClient: paymentAPIClient)
            self.gamePlayerManager = DefaultGamePlayerManager(paymentAPIClient: paymentAPIClient)
            
            self.gameServerName = self.authSDKGameInfo.serverName ?? ""
            self.characterId = self.authSDKGameInfo.characterId ?? ""
            
            self.gameInfo?.serverName = self.gameServerName
            self.gameInfo?.characterId = self.characterId
            
            
            print("[DefaultPaymentManager] gameServerName = \(gameServerName)")
            print("[DefaultPaymentManager] characterId = \(characterId)")
        }
        
        private var sessionManager: SessionManager?
        private var deviceInfo: DeviceInfoStorage?
        private var appInfo: AppInfoStorage?
        private var gameInfo: GameInfoStorage?
        private var gamePlayerInfo: GamePlayerStorage?
 
        public func setAppVersion(_ appVersion: String) -> Builder {
            self.appVersion = appVersion
            return self
        }
        
        public func setOSVersion(_ osVersion: String) -> Builder {
            self.osVersion = osVersion
            return self
        }
        
        public func setInitializer(_ initializer: PaymentInitialializer) -> Builder {
            self.initializer = initializer
            return self
        }
        
        public func setAccessToken(_ accessToken: String) -> Builder {
//            self.accessToken = accessToken
            print("[DefaultPaymentManager] set access token by auth-sdk")
            do {
                let session = try authSDKSessionManager.getSession()
                self.accessToken = session?.accessToken ?? accessToken
            } catch {
                self.accessToken = accessToken
                print("[DefaultPaymentManager] set access token by client")
            }
            return self
        }
        
        public func setRefreshToken(_ refreshToken: String) -> Builder {
//            self.refreshToken = refreshToken
            do {
                print("[DefaultPaymentManager] set refresh token by auth-sdk")
                let session = try authSDKSessionManager.getSession()
                self.refreshToken = session?.refreshToken ?? refreshToken
            } catch {
                self.refreshToken = refreshToken
                print("[DefaultPaymentManager] set refresh token by clients")
            }
            return self
        }
        
        public func setDeviceId(_ deviceId: String) -> Builder {
            self.deviceId = deviceId
            return self
        }
        
        public func setPackageName(_ packageName: String) -> Builder {
            self.packageName = packageName
            return self
        }
        
        public func setGameId(_ gameId: Int) -> Builder {
            self.gameId = gameId
            return self
        }
        
        public func setServerId(_ serverId: Int) -> Builder {
            print("[DefaultPaymentManager] set server id by auth-sdk")
            // Try to get serverId from AuthSDK's GameInfoStorage
            if let serverId = authSDKGameInfo.serverID {
                self.serverId = serverId
                print("[DefaultPaymentManager] set server id by auth-sdk: \(self.serverId)")
            } else if serverId > 0 {
                // Use provided serverId if AuthSDK doesn't have one
                self.serverId = serverId
                print("[DefaultPaymentManager] set server id by client: \(self.serverId)")
            } else {
                self.serverId = serverId
                print("[DefaultPaymentManager] server id is empty")
            }
            self.gameInfo?.serverName = authSDKGameInfo.serverName
            return self
        }
        
        public func setServerGameId(_ serverId: String) -> Builder {
            print("[DefaultPaymentManager] set server id by auth-sdk")
            // Try to get serverId from AuthSDK's GameInfoStorage
            if let serverId = authSDKGameInfo.serverGameId {
                self.gameServerId = serverId
                print("[DefaultPaymentManager] set server id by auth-sdk: \(self.gameServerId)")
            } else if !gameServerId.isEmpty {
                // Use provided serverId if AuthSDK doesn't have one
                self.gameServerId = serverId
                print("[DefaultPaymentManager] set server id by client: \(self.gameServerId)")
            } else {
                self.gameServerId = serverId
                print("[DefaultPaymentManager] server id is empty")
            }
            self.gameInfo?.serverGameName = authSDKGameInfo.serverGameName
            return self
        }
        
        public func setGameUUID(_ gameUUID: String) -> Builder {
//            self.gameUUID = gameUUID
            print("[DefaultPaymentManager] set game uuid by auth-sdk")
            do {
                let session = try authSDKSessionManager.getSession()
                self.gameUUID = session?.gameUUID ?? gameUUID
            } catch {
                self.gameUUID = gameUUID
                print("[DefaultPaymentManager] set game uuid by client")
            }
            return self
        }
        
        public func setPhoneNumber(_ phoneNumber: String) -> Builder {
            self.phoneNumber = phoneNumber
            return self
        }
        
        public func setIsGuestUser(_ isGuestUser: Bool) -> Builder {
            self.guestUser = isGuestUser
            return self
        }
        
        public func build() -> DefaultPaymentManager {
            do {
                // Session
                print("init-payment-manager: refreshtoken: \(refreshToken)")
                print("init-payment-manager: accessToken: \(accessToken)")
                print("init-payment-manager: gameUUID: \(gameUUID)")
                
                try sessionManager?.saveSession(
                    authSession: .init(
                        gameUUID: gameUUID,
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        expireDate: Date()
                    ),
                    isRefreshToken: false
                )
            } catch {
//                throw PaymentError.unauthenticated()
            }
            
            do {
                // Device Info
                try deviceInfo?.saveDeviceId(deviceId)
                try deviceInfo?.saveOSVersion(osVersion)
                
                // Game Player Info
                try gamePlayerInfo?.savePhoneNumber(phoneNumber)
                try gamePlayerInfo?.saveIsGuestUser(guestUser)
                
            } catch {
//                throw PaymentError.sdkNotInitialized()
            }
            
            // App Info
            appInfo?.packageName = packageName
            appInfo?.appVersion = appVersion
            
            // Game Info
            gameInfo?.gameID = gameId
            gameInfo?.serverID = serverId
            gameInfo?.serverGameId = gameServerId
            gameInfo?.serverGameName = gameServerName
            gameInfo?.gameUUID = gameUUID
            
            BaseAnalytics.initialize(token: Environment.mixpanelKey)
            let properties: [String: Any] = [
                "packageName": packageName,
                "appVersion": appVersion,
                "osVersion": osVersion,
                "gameId": gameId,
                "gameServerId": gameServerId,
                "gameUUID": gameUUID,
                "isGuestUser": guestUser
            ]
            BaseAnalytics.track(event: "IAPInit", properties: ["request": properties.toMixpanelType()])
            return DefaultPaymentManager(builder: self)
                .setting(\.accessToken, accessToken)
                .setting(\.refreshToken, refreshToken)
                .setting(\.deviceId, deviceId)
                .setting(\.osVersion, osVersion)
                .setting(\.packageName, packageName)
                .setting(\.appVersion, appVersion)
                .setting(\.gameId, gameId)
                .setting(\.gameServerId, gameServerId)
                .setting(\.gameUUID, gameUUID)
                .setting(\.phoneNumber, phoneNumber)
                .setting(\.guestUser, guestUser)
                .setting(\.initializer, initializer)
                .setting(\.paymentGateway, paymentGateway)
                .setting(\.gamePlayerManager, gamePlayerManager)
        }
    }
    
    public func fetchGamePackages(gameId: Int, serverId: Int, size: Int, page: Int) -> AnyPublisher<[GamePackageStatusOutput], PaymentError> {
        guard let paymentGateway = self.paymentGateway else {
            return Fail(error: PaymentError.unknownError())
                .eraseToAnyPublisher()
        }
        return paymentGateway.getGamePackages(gamePackage: GetGamePackageParams(gameId: gameId, serverId: serverId, platform: "iOS", size: size, page: page))
    }
    
    public func fetchProducts(productIDs: [String]) -> AnyPublisher<[Product], PaymentError> {
        guard let paymentGateway = self.paymentGateway else {
            return Fail(error: PaymentError.unknownError())
                .eraseToAnyPublisher()
        }
        BaseAnalytics.track(event: self.appleGamePackages, properties: [self.request : productIDs.joined(separator: ",")])
        return paymentGateway.fetchProducts(productIDs: productIDs)
    }
    
    public func purchase(product: Product) -> AnyPublisher<AppleVerifiedTranskModel, PaymentError> {
        guard let paymentGateway = self.paymentGateway else {
            print("[PackageListViewModel] paymentGateway is nil")
            return Fail(error: PaymentError.unknownError())
                .eraseToAnyPublisher()
        }
        print("[PackageListViewModel] paymentGateway is Ok")
        return paymentGateway.purchase(product: product)
    }
    
    public func validateGamePackage(gamePackage: GamePackageInput) -> AnyPublisher<GamePackageStatusOutput, PaymentError> {
        guard let paymentGateway = self.paymentGateway else {
            return Fail(error: PaymentError.unknownError())
                .eraseToAnyPublisher()
        }
        return paymentGateway.validateGamePackage(gamePackage: GamePackageParams(sku: gamePackage.sku, price: gamePackage.price, gameId: gameId, serverId: serverId, platform: platform, appVersion: appVersion, sdkVersion: versionName, sign: ""))
    }
    
    public func verifyGamePackagePurchase(gamePackagePurchase: GamePackagePurchaseInput) -> AnyPublisher<PurchaseVerificationOutput, PaymentError> {
        guard let paymentGateway = self.paymentGateway else {
            return Fail(error: PaymentError.unknownError())
                .eraseToAnyPublisher()
        }
        return paymentGateway.verifyGamePackagePurchase(
            gamePackagePurchase: PurchaseVerificationParams(
                sku: gamePackagePurchase.sku,
                transactionId:  gamePackagePurchase.transactionId,
                signedTransactionInfo: gamePackagePurchase.signedTransactionInfo,
                gameId: gameId,
                serverId: "\(serverId)",
                platform: platform,
                appVersion: appVersion,
                sdkVersion: versionName,
                sign: "")
        )
    }
    
    public func deactiveAccount() -> AnyPublisher<DatalessOutput, PaymentError> {
        guard let gamePlayer = self.gamePlayerManager else {
            return Fail(error: PaymentError.unknownError())
                .eraseToAnyPublisher()
        }
        return gamePlayer.deactiveAccount()
            .eraseToAnyPublisher()
    }
}

// Helper to set private properties after init
private extension DefaultPaymentManager {
    func setting<T>(_ keyPath: WritableKeyPath<DefaultPaymentManager, T>, _ value: T) -> DefaultPaymentManager {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}

public extension DefaultPaymentManager {
    static let REFERSH_TOKEN_KEY: String = "KKSOFT.RefreshedToken"
}


