//
//  DefaultAuthAPIClient.swift
//  AuthSDK
//

import Foundation
import Combine
internal import Mixpanel

struct DefaultAuthAPIClient: AuthAPIClient, SDKInfo, DeviceIdentifiable, APIAnalytics {
   
    private let session: URLSession
    private let jsonDecoder: JSONDecoder = JSONDecoder()
    public var deviceSecretKey: String {
        return Environment.deviceSecretKey
    }
    
    private var sessionManager: SessionManager
    // 1st
    // MARK: - API Calls
    func initSDK(body: InitSDKRequestBody) -> AnyPublisher<AuthInitServerResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/games/info",
            method: "POST",
            header: nil,
            body: body.toDictionary()
        )
    }
    
    // 3rd
    func login(header: [String:Any]?, body: [String: Any]?) -> AnyPublisher<AuthSessionServerResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/auth/login",
            method: "POST",
            header: header,
            body: body
        )
    }
    
    // 2nd
    func getGameServers(gameId: Int) -> AnyPublisher<GameServerInfoServerResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/games/\(gameId)/servers",
            method: "GET",
            header: nil,
            body: nil
        )
    }
    
    func getGameServers(gameId: Int, header: [String: Any], body: [String: Any]) -> AnyPublisher<GameServerInfoServerResponse, any Error> {
        executeWithTokenRefresh(
            endpoint: "/sdk/api/v1/games/\(gameId)/servers",
            method: "POST",
            header: header,
            body: body
        )
    }

    func updateGameServers(gameId: Int, serverId: Int, header: [String: Any]) -> AnyPublisher<GamePlayerInfoServerResponse, Error> {
        let queryParam: [String: String] = [
            "gameId": "\(gameId)",
            "serverId": "\(serverId)"
        ]
        return executeWithTokenRefresh(
            endpoint: "/sdk/api/v1/characters/me",
            method: "GET",
            queryParameters: queryParam,
            header: header,
            body: nil
        )
    }
    
    func requestOTP(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<OTPSendableServerResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/auth/send-otp",
            method: "POST",
            header: header,
            body: body
        )
    }
    
    func resendOTP(header: [String : Any]?, body: [String : Any]?) -> AnyPublisher<OTPResendableServerResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/auth/resend-otp",
            method: "POST",
            header: header,
            body: body
        )
    }
    
    func verifyOTP(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<OTPVerifiableServerResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/auth/verify-otp",
            method: "POST",
            header: header,
            body: body
        )
    }
    
    // 3.1rd
    func phoneSignup(header: [String : Any]?, body: [String : Any]?) -> AnyPublisher<AuthSessionServerResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/auth/register",
            method: "POST",
            header: header,
            body: body
        )
    }
    
    func updateInfo(header: [String : Any]?, body: [String : Any]?) -> AnyPublisher<Bool, any Error> {
        execute(
            endpoint: "/sdk/api/v1/user/profile'",
            method: "PUT",
            header: header,
            body: body
        )
    }
  
    func refreshToken(body: [String : Any]?) -> AnyPublisher<AuthSessionServerResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/auth/refresh-token",
            method: "POST",
            header: nil,
            body: body
        )
    }

    func getCharacter(
        header: [String: Any],
        gameId: Int,
        serverId: Int
    ) -> AnyPublisher<GameUUIDServerResponse, Error> {

        let queryParam: [String: String] = [
            "gameId": "\(gameId)",
            "serverId": "\(serverId)"
        ]

        return executeWithTokenRefresh(
            endpoint: "/sdk/api/v1/characters/me",
            method: "GET",
            queryParameters: queryParam,
            header: header
        )
    }

    
    func logout() -> AnyPublisher<DatalessServerResponse, any Error> {
        executeWithTokenRefresh(
            endpoint: "/sdk/api/v1/users/logout",
            method: "POST",
            header: [:]
        )
    }
    
    func forgetPassword(header: [String : Any]?, body: [String : Any]?) -> AnyPublisher<DatalessServerResponse, any Error> {
        execute(
            endpoint: "/sdk/api/v1/auth/reset-password",
            method: "POST",
            header: header,
            body: body
        )
    }
    
    func linkSocialAccount(header: [String : Any]?, body: [String : Any]?) -> AnyPublisher<AuthSessionServerResponse, any Error> {
        executeWithTokenRefresh(endpoint: "/sdk/api/v1/auth/link-account",
                method: "POST",
                header: header,
                body: body
        )
    }
    
    func linkToNewAccount(header: [String : Any]?, body: [String : Any]?) -> AnyPublisher<AuthSessionServerResponse, any Error> {
        executeWithTokenRefresh(
            endpoint: "/sdk/api/v1/auth/link-account",
            method: "POST",
            header: header,
            body: body
        )
    }
    
    func deactivateAccount(header: [String : Any]) -> AnyPublisher<DatalessServerResponse, any Error> {
        return execute(
            endpoint: "/sdk/api/v1/users/deactivate", // https://go-staging.tekernal.net/sdk/api/v1/users/deactivate
            method: "POST",
            header: header,
            body: nil
        )
    }
    
    private func refreshToken() throws -> AnyPublisher<AuthSessionServerResponse, any Error> {
        let refreshToken: String
        do {
            guard let tk = try sessionManager.getSession()?.refreshToken else {
                return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
            }
            refreshToken = tk
        } catch {
            return Fail(error: AuthErrorResponse.unauthenticated()).eraseToAnyPublisher()
        }
        
        let gameStorage: any GameInfoStorage = DefaultGameInfoStorage()
        
        guard let packageName = gameStorage.packageName,
              let appVersion = gameStorage.appVersion,
              let gameId = gameStorage.gameID
        else {
            return Fail(error: AuthErrorResponse.appNotConfigured()).eraseToAnyPublisher()
        }
        
        guard let sign = try? SHA256Signature().sign(refreshToken: refreshToken) else {
            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
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
                debugPrint("--------- new session: serverResponse = \(newSession) ---------")
                let dto = newSession.data
                debugPrint("--------- new session: DTO = \(dto) ---------")
                try? sessionManager.saveSession(authSession: dto.toModel(), isRefreshToken: true)
            })
            .mapError { error -> Error in
                guard var authError = error as? AuthErrorResponse else {
                    return error
                }
                
                if authError.code == .TokenExpired,
                   authError.message.localizedCaseInsensitiveContains("token has expired") {
                    // Refresh token has expired – clear session and force logout flow
                    try? sessionManager.clear()
                    NotificationCenter.default.post(
                        name: NSNotification.Name(NotificationKeys.EXPIRATION_TOKEN_KEY),
                        object: nil
                    )
                    authError = .unauthenticated()
                }
                
                return authError
            }
            .eraseToAnyPublisher()
    }
    
    private func executeWithTokenRefresh<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        queryParameters: [String: Any]? = nil,
        header: [String: Any]? = nil,
        body: [String: Any]? = nil
    ) -> AnyPublisher<T, Error> {
        
        func makeRequest() -> AnyPublisher<T, Error> {
            execute(endpoint: endpoint, method: method, queryParameters: queryParameters, header: header, body: body)
           }
        
        func isAccessExpired(_ error: Error) -> Bool {
               guard let authError = error as? AuthErrorResponse else { return false }
               return (authError.code == .TokenExpired) ||
                      (authError.code == .UnknownError &&
                       authError.message.localizedCaseInsensitiveContains("jwt token already expired"))
           }
        
        return makeRequest()
            .tryCatch { error -> AnyPublisher<T, Error> in
                debugPrint("MakeRequest Error: \(error)")
                // Only refresh on clear expiry signals
                guard isAccessExpired(error) else {
                    debugPrint("MakeRequest Not Expired Error")
                    return Fail(error: error).eraseToAnyPublisher()
                }
                // Attempt refresh once, then retry
                return try self.refreshToken()
                    .flatMap { _ in
                        debugPrint("MakeRequest Doing")
                        return makeRequest()
                    }
                    .catch { refreshError -> AnyPublisher<T, Error> in
                        // If refresh token is invalid/expired → force logout
                        debugPrint("MakeRequest Catching Error")
                        if let authErr = refreshError as? AuthErrorResponse, authErr.code == .Unauthorized {
                            NotificationCenter.default.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
                        }
                        return Fail(error: refreshError).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Request Builder
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
    
    // MARK: - Execute
    
    private func execute<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        queryParameters: [String: Any]? = nil,
        header: [String:Any]? = nil,
        body: [String: Any]? = nil
    ) -> AnyPublisher<T, Error> {
        let request = buildRequest(endpoint: endpoint, method: method, queryParameters: queryParameters, requestHeader: header, body: body)
        
        debugPrint("🚀 [REQUEST] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")

        var properties: Properties = [:]
        
        if let header = request.allHTTPHeaderFields {
            debugPrint("📦 [HEADER]: \(header)")
            properties["header"] = header
        }
        
        if let body = request.httpBody, let json = String(data: body, encoding: .utf8) {
            debugPrint("📦 [BODY]: \(json)")
            properties["body"] = json
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                debugPrint("✅ [RESPONSE] \(response)")
                debugPrint("📨 [DATA]: \(String(data: data, encoding: .utf8) ?? "nil")")
                
                properties["response"] = String(data: data, encoding: .utf8) ?? "nil"

                BaseAnalytics.track(event: request.url?.relativePath ?? "nil", properties: sanitizeProperties(properties))
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                switch httpResponse.statusCode {
                case 200...209:
                    return try jsonDecoder.decode(T.self, from: data)
                case 401:
                    if let apiError = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                        switch apiError.code {
                        case AuthErrorCodeResponse.TokenExpired:
                            throw AuthErrorResponse.tokenExpired()
                            
                        case AuthErrorCodeResponse.CharacterNotFound:
//                            let notificationCenter = NotificationCenter.default
//                            notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
                            throw AuthErrorResponse.unauthenticated()

                        case AuthErrorCodeResponse.AccountNotExist:
                            throw AuthErrorResponse.accountNotExist()
                            
                        case AuthErrorCodeResponse.OTPInvalid:
                            throw AuthErrorResponse.otpInvalid()
                            
                        case AuthErrorCodeResponse.InvalidPhoneOrPassword:
                            throw AuthErrorResponse.invalidPhoneOrPasswordError()
                            
                        case AuthErrorCodeResponse.SignatureError:
                            throw AuthErrorResponse.invalidSignature()
                            
                        default:
                            throw AuthErrorResponse.unauthenticated()
                        }
                    } else {
                        throw AuthErrorResponse.unknownError()
                    }
                case 500:
                    if let apiError = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                        switch apiError.code {
                        case AuthErrorCodeResponse.UnknownError:
                            if(apiError.message.contains("Jwt token already expired")) {
//                                let notificationCenter = NotificationCenter.default
//                                notificationCenter.post(name: NSNotification.Name(NotificationKeys.EXPIRATION_TOKEN_KEY), object: nil)
                                throw AuthErrorResponse.tokenExpired()
                            } else {
                                throw AuthErrorResponse.unknownError()
                            }
                        default:
                            throw AuthErrorResponse.unknownError()
                        }
                    }
                    else {
                        throw AuthErrorResponse.unknownError()
                    }
                case 404:
                    if let apiError = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                        switch apiError.code {
                        case AuthErrorCodeResponse.AccountDeactivated:
                            try? sessionManager.clear()
                            throw AuthErrorResponse.accountDeactivated()
                        case AuthErrorCodeResponse.AccountNotExist:
                            throw AuthErrorResponse.accountNotExist()
                        default:
                            throw AuthErrorResponse.unknownError()
                        }
                    } else {
                        throw AuthErrorResponse.unknownError()
                    }
                case 400:
                    if let apiError = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                        switch apiError.code {
                        case AuthErrorCodeResponse.OTPInvalid:
                            throw AuthErrorResponse.otpInvalid()
                        case AuthErrorCodeResponse.NewPassordRepeated:
                            throw AuthErrorResponse.newPasswordRepeated()
                        default:
                            throw AuthErrorResponse.matchError()
                        }
                    } else {
                        throw AuthErrorResponse.unknownError()
                    }
                case 409:
                    if let apiError = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                        switch apiError.code {
                        case AuthErrorCodeResponse.TokenExpired:
//                            let notificationCenter = NotificationCenter.default
//                            notificationCenter.post(name: NSNotification.Name(NotificationKeys.UNAUTHENTICATED_TOKEN_KEY), object: nil)
                            throw AuthErrorResponse.tokenExpired()
                        case AuthErrorCodeResponse.OTPRequestManyTime:
                            throw AuthErrorResponse.otpRequestManyTime()
                        case AuthErrorCodeResponse.OTPInvalid:
                            throw AuthErrorResponse.otpInvalid()
                        case AuthErrorCodeResponse.SocialAccountLinked:
                            throw AuthErrorResponse.socialAccountLinked()
                        default:
                            throw AuthErrorResponse.unknownError()
                        }
                    } else {
                        throw AuthErrorResponse.unknownError()
                    }
                default:
                    if let errorData = try? jsonDecoder.decode(AuthErrorResponse.self, from: data) {
                        throw errorData
                    } else {
                        throw AuthErrorResponse.unknownError()
                    }
                }
            }
            .mapError { error in
                return error as? AuthErrorResponse ?? AuthErrorResponse.unknownError()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Init
    
    private init(builder: Builder) {
        self.session = builder.session
        self.sessionManager = KeyChainSessionManager()
    }
    
    // MARK: - Builder
    
    final class Builder {
        var session: URLSession = .shared
        
        public init() {}
        
        func setSession(_ session: URLSession) -> Builder {
            self.session = session
            return self
        }
        
        func build() -> DefaultAuthAPIClient {
            DefaultAuthAPIClient(builder: self)
        }
    }
}

extension DefaultAuthAPIClient {
    private func sanitizeProperties(_ properties: Properties) -> Properties {
        var sanitized = properties
        
        // 1) Remove header["Content-Type"]
        if var header = sanitized["header"] as? [String: Any] {
            header.removeValue(forKey: "Content-Type")
            sanitized["header"] = header
        }
        
        // 2) Direct field sanitizing (token/password)
        for (key, value) in sanitized {
            if let stringValue = value as? String {
                let lowerKey = key.lowercased()
                
                if lowerKey.contains("password") {
                    sanitized[key] = stringValue.maskedPassword()
                    continue
                }
                
                if lowerKey.contains("token") {
                    sanitized[key] = stringValue.truncatedMiddle()
                    continue
                }
            }
        }
        
        // 3) Sanitize sensitive fields inside any JSON string
        for (key, value) in sanitized {
            if let stringValue = value as? String {
                sanitized[key] = sanitizeSensitiveInString(stringValue)
            }
        }
        
        // 4) Flatten "response" JSON into response_* fields
        if let responseString = sanitized["response"] as? String,
           let data = responseString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            func flatten(prefix: String, dict: [String: Any]) {
                for (k, v) in dict {
                    let newKey = "\(prefix)_\(k)"
                    
                    if let nested = v as? [String: Any] {
                        // Nested object → recurse
                        flatten(prefix: newKey, dict: nested)
                    } else {
                        // Leaf / array / scalar
                        if let mpValue = toMixpanelValue(v) {
                            sanitized[newKey] = mpValue
                        }
                    }
                }
            }
            
            flatten(prefix: "response", dict: json)
            
            // Optionally drop the original raw response string
            sanitized.removeValue(forKey: "response")
        }
        
        return sanitized
    }
    
    // Helper: sanitize tokens + password inside any JSON/string value
    func sanitizeSensitiveInString(_ text: String) -> String {
        var result = text
        
        // 1) accessToken / refreshToken → truncate 3...3
        let tokenPattern = #"\"(accessToken|refreshToken)\"\s*:\s*\"([^\"]+)\""#
        if let regex = try? NSRegularExpression(pattern: tokenPattern) {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for match in matches.reversed() {
                guard match.numberOfRanges >= 3,
                      let tokenRange = Range(match.range(at: 2), in: result) else { continue }
                let originalToken = String(result[tokenRange])
                result.replaceSubrange(tokenRange, with: originalToken.truncatedMiddle())
            }
        }
        
        // 2) password → same-length mask
        let passwordPattern = #"\"password\"\s*:\s*\"([^\"]*)\""#
        if let regex = try? NSRegularExpression(pattern: passwordPattern) {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for match in matches.reversed() {
                guard match.numberOfRanges >= 2,
                      let pwdRange = Range(match.range(at: 1), in: result) else { continue }
                let originalPwd = String(result[pwdRange])
                result.replaceSubrange(pwdRange, with: originalPwd.maskedPassword())
            }
        }
        return result
    }
    
    // Convert Any from JSONSerialization into something that conforms to MixpanelType
    func toMixpanelValue(_ value: Any) -> MixpanelType? {
        if let s = value as? String {
            return s
        }
        if let b = value as? Bool {
            return b
        }
        if let n = value as? NSNumber {
            // Bool is also NSNumber, but we already handled Bool above.
            return n.doubleValue    // or n.intValue if you prefer Int
        }
        if let array = value as? [Any] {
            let mpArray: [MixpanelType] = array.compactMap { toMixpanelValue($0) }
            return mpArray
        }
        if let dict = value as? [String: Any] {
            var mpDict: [String: MixpanelType] = [:]
            for (k, v) in dict {
                if let converted = toMixpanelValue(v) {
                    mpDict[k] = converted
                }
            }
            return mpDict
        }
        if value is NSNull {
            return NSNull()
        }
        
        // Fallback as String
        return String(describing: value)
    }
}
