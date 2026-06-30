//
//  DefaultPaymentAPIClient.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation
import Combine
internal import Mixpanel

struct DefaultPaymentAPIClient : PaymentAPIClient, SDKInfo {
    private let session: URLSession
    private let jsonDecoder: JSONDecoder = JSONDecoder()
    
    private var sessionManager: SessionManager
//    private var deviceInfo: DeviceInfoStorage
    
    func initSDK(body: InitSDKRequestBody) -> AnyPublisher<PaymentSDKInitResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/games/info",
            method: "POST",
            header: nil,
            body: body.toDictionary()
        )
    }
    
    func validateGamePackage(body: [String : Any]?) -> AnyPublisher<GamePackageStatusResponse, any Error> {
        executeWithTokenRefresh(
            endpoint: "/sdk/api/v1/purchase/validate-package",
            method: "POST",
            header: [:],
            body: body
        )
    }
    
    func verifyGamePackagePurchase(body: [String : Any]?) -> AnyPublisher<PurchaseVerificationResponse, any Error> {
        executeWithTokenRefresh(
            endpoint: "/sdk/api/v1/purchase/verify",
            method: "POST",
            header: [:],
            body: body
        )
    }
    
    func deactiveAccount(header: [String : Any]) -> AnyPublisher<DatalessServerResponse, any Error> {
        executeWithTokenRefresh(
            endpoint: "/sdk/api/v1/users/deactivate",
            method: "POST",
            header: header
        )
    }
    
    func getGamePackages(body: [String : Any]?) -> AnyPublisher<GamePackagesResponse, any Error> {
        executeWithTokenRefresh(
            endpoint: "/sdk/api/v1/game-packages",
            method: "GET",
            queryParameters: body,
            header: [:]
        )
    }
    
    private func executeWithTokenRefresh<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        queryParameters: [String: Any]? = nil,
        header: [String: Any]? = nil,
        body: [String: Any]? = nil
    ) -> AnyPublisher<T, Error> {
        
        func makeRequest(using accessTokenOverride: String? = nil) -> AnyPublisher<T, Error> {
            var effectiveHeader = header ?? [:]
            if let override = accessTokenOverride {
                effectiveHeader["Authorization"] = "Bearer \(override)"
            }
            return execute(
                endpoint: endpoint,
                method: method,
                queryParameters: queryParameters,
                header: effectiveHeader,
                body: body
            )
           }
        
        func isAccessExpired(_ error: Error) -> Bool {
               guard let authError = error as? PaymentError else { return false }
               return (authError.code == .TokenExpired) ||
                      (authError.code == .UnknownError &&
                       authError.message.localizedCaseInsensitiveContains("jwt token already expired"))
           }
        
        return makeRequest()
            .tryCatch { error -> AnyPublisher<T, Error> in
                print("MakeRequest Error: \(error)")
                // Only refresh on clear expiry signals
                guard isAccessExpired(error) else {
                    print("MakeRequest Not Expired Error")
                    return Fail(error: error).eraseToAnyPublisher()
                }
                print("MakeRequest Expired Error")
                // Attempt refresh once, then retry
                return self.refreshToken()
                    .map { $0.data }
                    .flatMap { dto in
                        print("MakeRequest Doing")
                        return makeRequest(using: dto.accessToken)
                    }
                    .catch { refreshError -> AnyPublisher<T, Error> in
                        // If refresh token is invalid/expired → force logout
                        print("MakeRequest Catching Error \(refreshError)")
                        if let authErr = refreshError as? PaymentError, authErr.code == .Unauthorized {
                            NotificationCenter.default.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
                        }
                        return Fail(error: refreshError).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func buildRequest(endpoint: String,
                              method: String,
                              queryParameters: [String: Any]? = nil,
                              requestHeader: [String: Any]? = nil,
                              body: [String: Any]? = nil
    ) -> URLRequest {
        var components = URLComponents(url: Environment.current.baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)!
           
        if let queryParameters = queryParameters, !queryParameters.isEmpty {
            components.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }
        
        let url = components.url ?? Environment.current.baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if var header = requestHeader {
            if !header.contains(where: { $0.key == "Authorization" }) {
                if let accessToken = try? sessionManager.getSession()?.accessToken {
                    header["Authorization"] = "Bearer \(accessToken)"
                }
            }
            for (key, value) in header {
                request.setValue("\(value)", forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        
        return request
    }
    
    private func refreshToken() -> AnyPublisher<PaymentSessionServerResponse, any Error> {
        print("[PaymentSDK] refreshToken: enter")
        let refreshToken: String
        do {
            guard let tk = try sessionManager.getSession()?.refreshToken else {
                print("[PaymentSDK] refreshToken: missing refresh token")
                return Fail(error: PaymentError.unauthenticated()).eraseToAnyPublisher()
            }
            refreshToken = tk
        } catch {
            print("[PaymentSDK] refreshToken: session read error -> \(error)")
            return Fail(error: PaymentError.unauthenticated()).eraseToAnyPublisher()
        }
        
        let gameStorage: any GameInfoStorage = DefaultGameInfoStorage()
        
        guard let packageName = gameStorage.packageName,
              let appVersion = gameStorage.appVersion,
              let gameId = gameStorage.gameID
        else {
            print("[PaymentSDK] refreshToken: app/game not configured")
            return Fail(error: PaymentError.appNotConfigured()).eraseToAnyPublisher()
        }
        
        let deviceInfo: DeviceInfoStorage = DeviceInfoKeychainStorage()
        
        guard let deviceID = try? deviceInfo.getDeviceId() else {
            print("[PaymentSDK] refreshToken: missing device id")
            return Fail(error: PaymentError.sdkNotInitialized()).eraseToAnyPublisher()
        }
        
        print("refresh-token: device id: \(deviceID)")
        print("refresh-token: refresh token: \(refreshToken)")
        
        guard let sign = try? SHA256Signature().sign(refreshToken: refreshToken) else {
            print("[PaymentSDK] refreshToken: signature error")
            return Fail(error: PaymentError.sdkSignatureError()).eraseToAnyPublisher()
        }
        
        let body = RefreshTokenRequestBody(
            packageName: packageName,
            deviceId: deviceID,
            platform: platform,
            sdkVersion: versionName,
            appVersion: appVersion,
            gameId: gameId,
            refreshToken: refreshToken,
            sign: sign
        )

        return execute(
            endpoint: "/sdk/api/v1/auth/refresh-token",
            method: "POST",
            body: body.toDictionary()
        )
        .handleEvents(receiveOutput: { newSession in
            // Save new tokens into the session manager after successful refresh
            print("--------- new session: serverResponse = \(newSession) ---------")
            let dto = newSession.data
            print("--------- new session: DTO = \(dto) ---------")
            // Pass DTO to sessionManager so it can sync to AuthSDK with expireDate
            try? sessionManager.saveSession(authSession: dto.toModel(), isRefreshToken: true)
        })
        .mapError { error -> Error in
            guard var paymentError = error as? PaymentError else {
                return error
            }
            if paymentError.code == .TokenExpired,
               paymentError.message.localizedCaseInsensitiveContains("token has expired") {
                try? sessionManager.clear()
                NotificationCenter.default.post(
                    name: NSNotification.Name(NotificationKeys.EXPIRATION_TOKEN_KEY),
                    object: nil
                )
                paymentError = .unauthenticated()
            }
            
            return paymentError
        }
        .eraseToAnyPublisher()
    }
    
    private func execute<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        queryParameters: [String: Any]? = nil,
        header: [String:Any]? = nil,
        body: [String: Any]? = nil
    ) -> AnyPublisher<T, Error> {
//        let request = buildRequest(endpoint: endpoint, method: method, requestHeader: header, body: body)
//        
//        print("🚀 [REQUEST] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
//
//        if let header = request.allHTTPHeaderFields {
//            print("📦 [HEADER]: \(header)")
//        }
//        
//        if let body = request.httpBody, let json = String(data: body, encoding: .utf8) {
//            print("📦 [BODY]: \(json)")
//        }
        
        let request = buildRequest(endpoint: endpoint, method: method, queryParameters: queryParameters, requestHeader: header, body: body)
        
        print("🚀 [REQUEST] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        var properties: Properties = [:]
        
        if let header = request.allHTTPHeaderFields {
            print("📦 [HEADER]: \(header)")
            properties["header"] = header
        }
        
        if let body = request.httpBody, let json = String(data: body, encoding: .utf8) {
            print("📦 [BODY]: \(json)")
            properties["body"] = json
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                print("✅ [RESPONSE] \(response)")
                print("📨 [DATA]: \(String(data: data, encoding: .utf8) ?? "nil")")

                properties["response"] = String(data: data, encoding: .utf8) ?? "nil"
                
                BaseAnalytics.track(event: request.url?.relativePath ?? "nil", properties: sanitizeProperties(properties))
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw PaymentError.invalidResponse()
                }
                switch httpResponse.statusCode {
                case 200...209:
                    return try jsonDecoder.decode(T.self, from: data)

                case 401:
                    if let apiError = try? JSONDecoder().decode(PaymentError.self, from: data) {
                        switch apiError.code {
                        case PaymentErrorCode.TokenExpired:
//                            let notificationCenter = NotificationCenter.default
//                            notificationCenter.post(name: NSNotification.Name(NotificationKeys.EXPIRATION_TOKEN_KEY), object: nil)
                            throw PaymentError.tokenExpired()

                        case PaymentErrorCode.AccountNotExist:
                            throw PaymentError.accountNotExist()
                            
                        default:
                            throw PaymentError.unauthenticated()
                        }
                    } else {
                        throw PaymentError.unknownError()
                    }
                case 400:
                    if let apiError = try? JSONDecoder().decode(PaymentError.self, from: data) {
                        switch apiError.code {
                        
                        default:
                            throw PaymentError.matchError()
                        }
                    } else {
                        throw PaymentError.unknownError()
                    }
                case 409:
                    if let apiError = try? JSONDecoder().decode(PaymentError.self, from: data) {
                        switch apiError.code {
                        case PaymentErrorCode.TokenExpired:
//                            let notificationCenter = NotificationCenter.default
//                            notificationCenter.post(name: NSNotification.Name(NotificationKeys.EXPIRATION_TOKEN_KEY), object: nil)
                            throw PaymentError.tokenExpired()
                        default:
                            throw PaymentError.unknownError()
                        }
                    } else {
                        throw PaymentError.unknownError()
                    }
                case 500:
                    if let apiError = try? JSONDecoder().decode(PaymentError.self, from: data) {
                        switch apiError.code {
                        case PaymentErrorCode.UnknownError:
                            if(apiError.message.contains("Jwt token already expired")) {
//                                let notificationCenter = NotificationCenter.default
//                                notificationCenter.post(name: NSNotification.Name(NotificationKeys.EXPIRATION_TOKEN_KEY), object: nil)
                                throw PaymentError.tokenExpired()
                            } else {
                                throw PaymentError.unknownError()
                            }
                        default:
                            throw PaymentError.unknownError()
                        }
                    }
                    else {
                        throw PaymentError.unknownError()
                    }
                default:
                    if let errorData = try? jsonDecoder.decode(PaymentError.self, from: data) {
                        throw errorData
                    } else {
                        throw PaymentError.unknownError()
                    }
                }
            }
            .mapError { error in
                return error as? PaymentError ?? PaymentError.unknownError()
            }
            .eraseToAnyPublisher()
    }
    
    private init(builder: Builder) {
        self.session = builder.session
        self.sessionManager = KeyChainSessionManager()
//        self.deviceInfo = DeviceInfoKeychainStorage()
    }
    
    // MARK: - Builder
    
    final class Builder {
        var session: URLSession = .shared
        
        public init() {}
        
        func setSession(_ session: URLSession) -> Builder {
            self.session = session
            return self
        }
        
        func build() -> DefaultPaymentAPIClient {
            DefaultPaymentAPIClient(builder: self)
        }
    }
}


extension DefaultPaymentAPIClient {

    private func sanitizeProperties(_ properties: Properties) -> Properties {
        var sanitized = properties

        // ✅ 1. Sanitize header.Authorization
        if var header = sanitized["header"] as? [String: Any],
           let authorization = header["Authorization"] as? String {

            header["Authorization"] = authorization.truncatedMiddle()
            sanitized["header"] = header
        }

        // ✅ 2. Sanitize signedTransactionInfo inside JSON body (string)
        if let bodyString = sanitized["body"] as? String {
            sanitized["body"] = sanitizeSignedTransactionInfo(in: bodyString)
        }

        return sanitized
    }

    // MARK: - Helpers

    private func sanitizeSignedTransactionInfo(in jsonString: String) -> String {
        var result = jsonString

        let pattern = #""signedTransactionInfo"\s*:\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return jsonString
        }

        let matches = regex.matches(
            in: jsonString,
            range: NSRange(jsonString.startIndex..., in: jsonString)
        )

        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: jsonString) else { continue }
            let original = String(jsonString[range])
            let truncated = original.truncatedMiddle()
            result.replaceSubrange(range, with: truncated)
        }

        return result
    }
}
