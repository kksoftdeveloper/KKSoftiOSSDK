import Combine
import FBSDKCoreKit
import FBSDKLoginKit
import UIKit

extension SocialAccountLinker {
    func facebookAccountLinker() -> AnyPublisher<AuthSessionResponse, Error> {
        return Future<AuthSessionResponse, Error> { [weak self] promise in
            do {
                let _: FacebookLoginParameters = try FacebookLoginParameters.fromSensitiveData()
                guard let deviceId = self?.deviceID, !deviceId.isEmpty else {
                    BaseAnalytics.track(event: self?.linkToFacebookAccount ?? "LinkToFacebookAccount", properties: [self?.failure ?? "failure" : AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let platform = self?.platform, !platform.isEmpty else {
                    BaseAnalytics.track(event: self?.linkToFacebookAccount ?? "LinkToFacebookAccount", properties: [self?.failure ?? "failure" : AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let appVersion = self?.gameInfoStorage.appVersion, !appVersion.isEmpty else {
                    BaseAnalytics.track(event: self?.linkToFacebookAccount ?? "LinkToFacebookAccount", properties: [self?.failure ?? "failure" : AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let sdkVersion = self?.versionName, !sdkVersion.isEmpty else {
                    BaseAnalytics.track(event: self?.linkToFacebookAccount ?? "LinkToFacebookAccount", properties: [self?.failure ?? "failure" : AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }
                
                guard let gameId = self?.gameInfoStorage.gameID else {
                    BaseAnalytics.track(event: self?.linkToFacebookAccount ?? "LinkToFacebookAccount", properties: [self?.failure ?? "failure" : AuthErrorResponse.appNotConfiguredGame().message])
                    promise(.failure(AuthErrorResponse.appNotConfiguredGame()))
                    return
                }
                
                guard let accessToken = try? self?.sessionManager.getSession()?.accessToken else {
                    BaseAnalytics.track(event: self?.linkToFacebookAccount ?? "LinkToFacebookAccount", properties: [self?.failure ?? "failure" : AuthErrorResponse.facebookAuthenticateError().message])
                    promise(.failure(AuthErrorResponse.facebookAuthenticateError()))
                    return
                }
                
                guard let serverId = self?.gameInfoStorage.serverID else {
                    BaseAnalytics.track(event: self?.linkToFacebookAccount ?? "LinkToFacebookAccount", properties: [self?.failure ?? "failure" : AuthErrorResponse.facebookAuthenticateError().message])
                    promise(.failure(AuthErrorResponse.appNotConfiguredGameServer()))
                    return
                }
                
                print("access-token: --- \(accessToken)")
                
//                let header = ["Authorization": "Bearer \(accessToken)"]
                
                self?.requestLogin { [weak self] result in
                    guard let self = self else {
                        BaseAnalytics.track(event: self?.linkToFacebookAccount ?? "LinkToFacebookAccount", properties: [self?.failure ?? "failure" : AuthErrorResponse.facebookUnknownError().message])
                        promise(.failure(AuthErrorResponse.facebookUnknownError()))
                        return
                    }
                    switch result {
                    case .success(let token):
                        
                        guard let sign = try? signature.sign(token: token, type: "facebook") else {
                            BaseAnalytics.track(event: self.linkToFacebookAccount, properties: [self.failure: AuthErrorResponse.sdkSignatureError().message])
                            promise(.failure(AuthErrorResponse.sdkSignatureError()))
                            return
                        }
                        
                        let body = SocialLinkAccountRequestBody.init(token: token,
                                                                     type: "facebook",
                                                                     deviceId: deviceId,
                                                                     appVersion: appVersion,
                                                                     platform: platform,
                                                                     sdkVersion: sdkVersion,
                                                                     gameId: gameId,
                                                                     serverId: serverId,
                                                                     sign: sign
                        )
                        BaseAnalytics.track(event: self.linkToFacebookAccount, properties: [self.request: body.toDictionary()])

                        self.authAPIClient.linkSocialAccount(header: [:], body: body.toDictionary())
                            .tryMap { sessionDTO in
                                let model = sessionDTO.data.toModel()
                                self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                                try? self.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                                try? self.gamePlayerStorage.saveIsGuestUser(false)
                                try? self.gamePlayerStorage.savePhoneNumber("")
                                return model.toResponse()
                            }
                            .sink(receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    BaseAnalytics.track(event: self.linkToFacebookAccount, properties: [self.failure: error.localizedDescription])
                                    promise(.failure(error))
                                }
                            }, receiveValue: { response in
                                promise(.success(response))
                            })
                            .store(in: &self.cancellables)
                        
                    case .failure(let error):
                        BaseAnalytics.track(event: self.linkToFacebookAccount, properties: [self.failure: error.localizedDescription])
                        promise(.failure(AuthErrorResponse.facebookUnknownError()))
                    }
                }
            } catch {
                BaseAnalytics.track(event: self?.linkToFacebookAccount ?? "LinkToFacebookAccount", properties: [self?.failure ?? "failure": error.localizedDescription])
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    private func requestLogin(_ completion: @escaping (Result<String, Error>) -> Void) {
        // Ensure the configuration object is valid
        guard let configuration = LoginConfiguration(
            permissions:["email", "public_profile"],
            tracking: .limited,
            nonce: UUID().uuidString
        )
        else {
            completion(.failure(AuthErrorResponse.facebookUnknownError()))
            return
        }
        DispatchQueue.main.async {
            self.fbLoginManager.logOut()
//            if let token = AccessToken.current, token.isExpired == false {
//                self.logInfo(token)
//                completion(.success(token.tokenString))
//                return
//            }
            guard let presentingVC = UIApplication.shared.authSDKTopViewController else {
//                BaseAnalytics.track(event: self?.googleLogin ?? "GoogleLogin", properties: [self?.failure ?? "failure": AuthErrorResponse.googleUnknownError().message])
                completion(.failure(AuthErrorResponse.facebookUnknownError()))
                return
            }
            self.fbLoginManager.logIn(viewController: presentingVC, configuration: configuration, completion: { result in
                switch result {
                case .cancelled:
                    print("FB Login cancelled")
                    completion(.failure(AuthErrorResponse.socialUserCancels()))
                    break
                
                case .failed:
                    print("FB Login failed")
                    completion(.failure(AuthErrorResponse.facebookUnknownError()))
                    break
                
                case .success:
                    // getting id token string
                    if let tokenString = AuthenticationToken.current?.tokenString {
                        print("FB Login success \(tokenString)")
                        completion(.success(tokenString))
                        
                    } else {
                        print("FB Login unauthenticaed")
                        completion(.failure(AuthErrorResponse.facebookAuthenticateError()))
                    }
                    break
                }
            })
        }
    }
    
    private func logInfo(_ token: AccessToken) {
#if DEBUG
        print("✅ Login with facebook success!" +
              "\nGranted permission: \(token.permissions)" +
              "\nDeclined permission: \(token.declinedPermissions)" +
              "\nUserID: \(token.userID)" +
              "\nAccess Token: \(token.tokenString)")
#endif
    }
}
