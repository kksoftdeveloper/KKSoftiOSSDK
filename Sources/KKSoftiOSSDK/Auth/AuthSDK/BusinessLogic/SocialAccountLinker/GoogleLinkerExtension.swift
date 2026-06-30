import Foundation
import Combine
import GoogleSignIn
import UIKit

extension SocialAccountLinker {
    
    func googleAccountLinker() -> AnyPublisher<AuthSessionResponse, Error> {
        return Future<AuthSessionResponse, Error> { [weak self] promise in
            do {
                let _: GoogleLoginParameters = try GoogleLoginParameters.fromSensitiveData()

                guard let self else {
                    BaseAnalytics.track(event: self?.linkToGoogleAccount ?? "LinkToGoogleAccount", properties: [self?.failure ?? "failure" :AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }

                guard !self.deviceID.isEmpty else {
                    BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure :AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }

                guard !self.platform.isEmpty else {
                    BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure :AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }

                guard let appVersion = self.gameInfoStorage.appVersion, !appVersion.isEmpty else {
                    BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure :AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }

                guard !self.versionName.isEmpty else {
                    BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure :AuthErrorResponse.sdkNotInitialized().message])
                    promise(.failure(AuthErrorResponse.sdkNotInitialized()))
                    return
                }

                guard let gameId = self.gameInfoStorage.gameID else {
                    BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure :AuthErrorResponse.appNotConfiguredGame().message])
                    promise(.failure(AuthErrorResponse.appNotConfiguredGame()))
                    return
                }

                guard let presentingVC = UIApplication.shared.authSDKTopViewController else {
                    BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure :AuthErrorResponse.googleUnknownError().message])
                    promise(.failure(AuthErrorResponse.googleUnknownError()))
                    return
                }

                self.performGoogleSignIn(presentingVC: presentingVC)
                    .flatMap { oauthToken -> AnyPublisher<AuthSessionResponse, Error> in
                        guard let _ = try? self.sessionManager.getSession()?.accessToken else {
                            BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure :AuthErrorResponse.googleAuthenticateError().message])
                            return Fail(error: AuthErrorResponse.googleAuthenticateError()).eraseToAnyPublisher()
                        }
                        
                        guard let sign = try? self.signature.sign(token: oauthToken, type: "google") else {
                            BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure :AuthErrorResponse.sdkSignatureError().message])
                            return Fail(error: AuthErrorResponse.sdkSignatureError()).eraseToAnyPublisher()
                        }
                        
                        guard let serverId = self.gameInfoStorage.serverID else {
                            BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure :AuthErrorResponse.appNotConfiguredGameServer().message])
                            return Fail(error: AuthErrorResponse.appNotConfiguredGameServer()).eraseToAnyPublisher()
                        }
                        

                        let body = SocialLinkAccountRequestBody(
                            token: oauthToken,
                            type: "google",
                            deviceId: self.deviceID,
                            appVersion: appVersion,
                            platform: self.platform,
                            sdkVersion: self.versionName,
                            gameId: gameId,
                            serverId: serverId,
                            sign: sign
                        )

                        BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.request : body.toDictionary().toMixpanelType()])
                        
//                        let header = ["Authorization": "Bearer \(accessToken)"]

                        return self.authAPIClient.linkSocialAccount(header: [:], body: body.toDictionary())
                            .tryMap { sessionDTO in
                                let model = sessionDTO.data.toModel()
                                self.gameInfoStorage.gameUUID = sessionDTO.data.gameUUID
                                try? self.sessionManager.saveSession(authSession: model, isRefreshToken: false)
                                try? self.gamePlayerStorage.savePhoneNumber("")
                                try? self.gamePlayerStorage.saveIsGuestUser(false)
                                return model.toResponse()
                            }
                            .eraseToAnyPublisher()
                    }
                    .sink(receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            BaseAnalytics.track(event: self.linkToGoogleAccount, properties: [self.failure : error.localizedDescription])
                            promise(.failure(error))
                        }
                    }, receiveValue: { response in
                        promise(.success(response))
                    })
                    .store(in: &self.cancellables)

            } catch {
                BaseAnalytics.track(event: self?.linkToGoogleAccount ?? "LinkToGoogleAccount", properties: [self?.failure ?? "failure" : error.localizedDescription])
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    
    private func performGoogleSignIn(presentingVC: UIViewController) -> Future<String, Error> {
        return Future { promise in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }

                guard let result = result,
                      let token = result.user.idToken?.tokenString else {
                    promise(.failure(AuthErrorModel.googleNoResultError()))
                    return
                }

                promise(.success(token))
            }
        }
    }
}
