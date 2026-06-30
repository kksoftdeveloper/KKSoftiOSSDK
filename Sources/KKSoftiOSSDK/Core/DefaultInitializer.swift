//
//  Initializer.swift
//  AuthSDK
//

import Foundation
import Combine

final class DefaultInitializer : InitializeAnalytics, Initialializer, DeviceIdentifiable, SDKInfo {
   
    private var authAPIClient: AuthAPIClient
    private var apiClient: PaymentAPIClient
    private var gameInfoStorage: GameInfoStorage
    private var appInfoStorage: AppInfoStorage
    private var deviceInfoStorage: DeviceInfoStorage
    private var signature: Signature
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    init(authAPIClient: AuthAPIClient,
         gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage(),
         signature: Signature = SHA256Signature()
    ) {
        self.authAPIClient = authAPIClient
        self.apiClient = DefaultPaymentAPIClient.Builder().build()
        self.gameInfoStorage = gameInfoStorage
        self.appInfoStorage = DefaultAppInfoStorage()
        self.deviceInfoStorage = DeviceInfoKeychainStorage()
        self.signature = signature
    }
    
    func initSDK(packageName: String, appVersion: String, serverId: Int) -> AnyPublisher<AuthInitResponse, any Error>  {
        let timeStamp = Int(Date().timeIntervalSince1970)
        
        gameInfoStorage.packageName = packageName
        gameInfoStorage.appVersion = appVersion
        
        guard let signature = try? self.signature.sign(timestampInSeconds: timeStamp) else {
            BaseAnalytics.track(event: self.eventName, properties: [self.failure : AuthErrorResponse.sdkSignatureError().message])
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
        }
        
//        gameInfoStorage.serverID = serverId
        
        let body = InitSDKRequestBody(
            packageName: packageName,
            deviceId: deviceID,
            platform: platform,
            sdkVersion: versionName,
            appVersion: appVersion,
            timestamp: timeStamp,
            sign: signature
        )
        
        BaseAnalytics.track(event: eventName, properties: [request : body.toDictionary().toMixpanelType()])
        return authAPIClient.initSDK(body: body)
            .tryMap { [weak self] initResDTO -> (response: AuthInitResponse, gameId: Int, serverId: String) in
                guard let self else { throw AuthErrorResponse.unknownError() }
                
                let model = initResDTO.data.toModel()
                
                self.gameInfoStorage.gameID = model.gameInfoModel?.gameID ?? 1
                self.gameInfoStorage.packageName = packageName
                self.gameInfoStorage.appVersion = appVersion
                self.gameInfoStorage.timeToRemindLogin = initResDTO.data.guestLoginAfterSeconds ?? 0
                
                let infoDictionary = Bundle.main.infoDictionary
                if let fbClientID = [model.facebookConfigModel?.clientId, infoDictionary?["FacebookAppID"] as? String]
                    .compactMap({ $0?.configuredValue })
                    .first {
                    try SensitiveDataManager.shared.set(fbClientID, for: .facebookClientID)
                }
                if let fbSecretClient = [model.facebookConfigModel?.clientToken, infoDictionary?["FacebookClientToken"] as? String]
                    .compactMap({ $0?.configuredValue })
                    .first {
                    try SensitiveDataManager.shared.set(fbSecretClient, for: .facebookClientSecret)
                }
                if let ggClientID = [model.googleConfigModel?.clientId, infoDictionary?["GIDClientID"] as? String]
                    .compactMap({ $0?.configuredValue })
                    .first {
                    try SensitiveDataManager.shared.set(ggClientID, for: .googleClientID)
                }
                if let ggURLSchema = [model.googleConfigModel?.platformUrlSchema, infoDictionary?["GIDReversedClientID"] as? String]
                    .compactMap({ $0?.configuredValue })
                    .first {
                    try SensitiveDataManager.shared.set(ggURLSchema, for: .googleURLSchema)
                }
                
                guard let response = try model.toResponse() else {
                    BaseAnalytics.track(event: self.eventName, properties: [self.failure : "Serialization Error"])
                    throw AuthErrorResponse.appNotFound()
                }
                
                BaseAnalytics.track(event: self.eventName, properties: [self.success : response.toDictionary().toMixpanelType()])
                
                let gameId = response.gameInfo.gameId
                print("SERVER: given-server = \(serverId)")
                print("SERVER: set-gameId \(gameId)")
                return (response, gameId, String(serverId))
            }
            .flatMap { [weak self] pair -> AnyPublisher<AuthInitResponse, Error> in
                guard let self else {
                    print("SERVER: self = nil")
                    return Fail(error: AuthErrorResponse.unknownError()).eraseToAnyPublisher()
                }
                let (response, gameId, serverId) = pair
                print("SERVER: pair = \(pair)")
                return self.authAPIClient.getGameServers(gameId: gameId)
                    .tryMap { resDTO in
                        let ret = resDTO.data.map { dto in
                            dto.toModel().toResponse()
                        }
                        print("SERVER: Server List = \(ret)")
                        return ret
                    }
                    .tryMap { (servers: [GameServerInfoResponse]) -> AuthInitResponse in
                        guard !servers.isEmpty else {
                            let notificationCenter = NotificationCenter.default
                            notificationCenter.post(name: NSNotification.Name(NotificationKeys.SERVER_MAINTENANCE_KEY), object: nil)
                            throw AuthErrorResponse.appNotConfiguredGameServer()
                        }
                        print("SERVER: Selected ServerId = \(serverId)")
                        let selectedServer = servers.first {
                            $0.serverClientId?.lowercased() == serverId.lowercased()
                        } ?? servers.first {
                            $0.serverStatus == .online
                        } ?? servers.first

                        guard let selectedServer else {
                            self.gameInfoStorage.serverID = nil
                            self.gameInfoStorage.serverName = nil
                            throw AuthErrorResponse.appNotConfiguredGameServer()
                        }

                        print("SERVER: Selected Server = \(selectedServer.serverId)")
                        self.gameInfoStorage.serverID = selectedServer.serverId
                        self.gameInfoStorage.serverName = selectedServer.serverName
//                        guard servers.contains(where: {
//                            print("Selected compaired to selected server: \($0.serverId) & \(serverId.lowercased())")
//                            isGoodGivenServerId = $0.serverId.lowercased() == serverId.lowercased()
//                            
//                        }) else {
//                            let notificationCenter = NotificationCenter.default
//                            notificationCenter.post(name: NSNotification.Name(NotificationKeys.SERVER_MAINTENANCE_KEY), object: nil)
//                            throw AuthErrorResponse.appNotConfiguredGameServer()
//                        }
                        return response
                    }
                    .eraseToAnyPublisher()
            }
            .mapError { [weak self] error -> Error in
                self?.trackAndWrap(error) ?? error
            }
            .eraseToAnyPublisher()
    }

    @discardableResult
    private func trackAndWrap(_ error: Error) -> Error {
        let domainError: Error
        if let e = error as? AuthErrorResponse {
            domainError = e
        } else {
            domainError = AuthErrorResponse.unknownError()
        }
        BaseAnalytics.track(event: eventName, properties: [failure: "\(domainError)"])
        return domainError
    }
    
    init(apiClient: PaymentAPIClient,
             gameInfoStorage: GameInfoStorage = DefaultGameInfoStorage(),
             appInfoStorage: AppInfoStorage = DefaultAppInfoStorage(),
             deviceInfoStorage: DeviceInfoStorage = DeviceInfoKeychainStorage(),
             signature: Signature = SHA256Signature()
        ) {
            self.authAPIClient = DefaultAuthAPIClient.Builder().build()
            self.apiClient = apiClient
            self.gameInfoStorage = gameInfoStorage
            self.appInfoStorage = appInfoStorage
            self.deviceInfoStorage = deviceInfoStorage
            self.signature = signature
        }

        func initSDK() -> AnyPublisher<DatalessOutput, Error> {
            
            guard let packageName = appInfoStorage.packageName else {
                return Fail(error: PaymentError.sdkNotInitialized()).eraseToAnyPublisher()
            }
            
            guard let appVersion = appInfoStorage.appVersion else {
                return Fail(error: PaymentError.sdkNotInitialized()).eraseToAnyPublisher()
            }
            
            guard let deviceId: String = try? deviceInfoStorage.getDeviceId() else {
                return Fail(error: PaymentError.sdkNotInitialized()).eraseToAnyPublisher()
            }
            
            let timeStamp = Int(Date().timeIntervalSince1970)
            
            guard let signature = try? self.signature.sign(timestampInSeconds: timeStamp) else {
                return Fail(error: PaymentError.sdkNotInitialized()).eraseToAnyPublisher()
            }
            
            let body = InitSDKRequestBody(
                packageName: packageName,
                deviceId: deviceId,
                platform: platform,
                sdkVersion: versionName,
                appVersion: appVersion,
                timestamp: timeStamp,
                sign: signature
            )
            
            return apiClient.initSDK(body: body)
                .tryMap { initResDTO in
                    
                    return DatalessOutput(status: 1, message: "Success")
                }
                .eraseToAnyPublisher()
        }
}

struct InitSDKRequestBody: Encodable {
    let packageName: String
    let deviceId: String
    let platform: String
    let sdkVersion: String
    let appVersion: String
    let timestamp: Int
    let sign: String
    
    private enum CodingKeys: String, CodingKey {
        case packageName = "packageName"
        case deviceId = "deviceId"
        case platform = "platform"
        case sdkVersion = "sdkVersion"
        case appVersion = "appVersion"
        case timestamp = "timestamp"
        case sign = "sign"
    }
}
