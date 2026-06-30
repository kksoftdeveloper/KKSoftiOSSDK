//
//  WelcomeViewModel.swift
//  AuthSDK
//

import Foundation
import Combine
import UIKit
import SwiftUI

@MainActor
public class WelcomeViewModel: OpenViewModel, AnalyticsProperties {
    
    public var deviceSecretKey: String {return Environment.deviceSecretKey}
    
    public enum FocusField: Hashable {
        case phone
        case password
        case terms
    }
    
    public struct LoginFormState {
        var phoneNumber: String = ""
        var password: String = ""
        var isAcceptedTerm: Bool = false
        var isLoginEnabled: Bool = false
    }

    @Published public var formState = LoginFormState()
    @Published public var focusedField: FocusField? = nil
    @Published public var shouldHighlightTerms = false
    @Published public var errorMessage: String?
//    @Published var isAcceptedTerm = false
//    @Published var phoneNumber = ""
//    @Published var password = ""
    @Published var presentedScreen: PopupScreen?
//    @Published var isLoginEnabled = false
    @Published var currentFlowType: FlowType? = nil
    
    let authManager: AuthManager
    
    public var onLoginSuccess: ((AuthSessionResponse) -> Void)
    public var onLoginFailure: ((AuthErrorResponse) -> Void)
    
    var onClose: (() -> Void)
    
    @Published var authSession: AuthSessionResponse?
    
    private var autoLinkTask: Task<Void, Never>?
    @Published var remainingSeconds: Int = 0
    
    private var timerCancellable: AnyCancellable?
    private let popupInterval = 60  // seconds
    private var pendingLoginCompletionSession: AuthSessionResponse?
    
    deinit {
        timerCancellable?.cancel()
    }

    public init(
        authManager: AuthManager,
//        isAcceptedTerm: Bool = false,
        onLoginSuccess: @escaping ((AuthSessionResponse) -> Void),
        onLoginFailure: @escaping ((AuthErrorResponse) -> Void),
        onClose: @escaping (() -> Void)
    ) {
//        self.isAcceptedTerm = isAcceptedTerm
        self.onLoginSuccess = onLoginSuccess
        self.onLoginFailure = onLoginFailure
        self.onClose = onClose
        self.authManager = authManager
        
        super.init()
//        Publishers
//            .CombineLatest3($phoneNumber, $password, $isAcceptedTerm)
//            .map { phone, pass, accepted in
//                phone.isValidPhoneNumber() && pass.isStrongPassword() && accepted
//            }
//            .assign(to: \.isLoginEnabled, on: self)
//            .store(in: &cancellables)
        
        // Enable login button when form is valid and terms accepted
        $formState
          .map { form in
            form.phoneNumber.isValidPhoneNumber()
             && form.password.isStrongPassword()
             && form.isAcceptedTerm
          }
          .receive(on: DispatchQueue.main)
          .sink { [weak self] isEnabled in
//            self?.formState.isLoginEnabled = isEnabled
              guard let self = self else { return }
              if self.formState.isLoginEnabled != isEnabled {
                  self.formState.isLoginEnabled = isEnabled
              }
          }
          .store(in: &cancellables)
    }
    
    // MARK: - Submission Handling
    public func handleSubmit(from field: FocusField) {
        switch field {
        case .phone:
            focusedField = .password
        case .password:
            if !formState.isAcceptedTerm {
                focusedField = .terms
                highlightTerms()
            } else {
                login()
            }
        case .terms:
            login()
        }
    }

    
    private func highlightTerms() {
        shouldHighlightTerms = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.shouldHighlightTerms = false
        }
    }
    
    func initSDK(packageName: String, appVersionName: String, serverId: Int) {
        BaseAnalytics.initialize(token: token)
        guard !appVersionName.isEmpty else {
            let _ = LocalizedStringKey.sdkAsset("version_empty").toString()
            onLoginFailure(.matchError())
            return
        }
        
        guard !packageName.isEmpty else {
            let _ = LocalizedStringKey.sdkAsset("package_name_empty").toString()
            onLoginFailure(.matchError())
            return
        }
        
        authManager.initSDK(packageName: packageName, appVersion: appVersionName, serverId: serverId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    debugPrint("❌ initSDK failed:", (error as? AuthErrorResponse)?.message ?? error.localizedDescription)
                    let errorMessage = (error as? AuthErrorResponse)?.message ?? LocalizedStringKey.sdkAsset("unknown_error_message").toString()
//                    let err = error as? AuthErrorResponse ?? .unknownError()
//                    self.onLoginFailure(err)
                    
                case .finished:
                    break
                }
            }, receiveValue: { gameInfo in
                
                debugPrint("✅ initSDK success:", gameInfo)
            })
            .store(in: &cancellables)
    }
    
    func login() {
        guard formState.isLoginEnabled else { return }
        isLoading = true
        authManager.login(phoneNumber: formState.phoneNumber, password: formState.password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    debugPrint("❌ Login Error: \(error)")
                    let err = (error as? AuthErrorResponse) ?? .unknownError()
                    if err.code == AuthErrorCodeResponse.InvalidPhoneOrPassword {
                        errorMessage = LocalizedStringKey.sdkAsset("invalid_phone_or_password").toString()
                    } else if err.code == AuthErrorCodeResponse.AccountDeactivated {
                        errorMessage = LocalizedStringKey.sdkAsset("account_is_deleted").toString()
                    } else {
                        errorMessage = LocalizedStringKey.sdkAsset("unknown_error_message").toString()
                    }
                    self.onLoginFailure(err)
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] data in
                guard let self else { return }
                self.isLoading = false
                debugPrint("✅ Login Success: \(data)")
                self.completeLoginIfProfileReady(data)
            })
            .store(in: &cancellables)
    }
    
    func loginFacebook() {
        isLoading = true
        authManager.loginWithFacebookAccount()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    debugPrint("❌ Login Facebook Error: \(error)")
                    let err = (error as? AuthErrorResponse) ?? .unknownError()
                    if err.code == AuthErrorCodeResponse.InvalidPhoneOrPassword {
                        errorMessage = LocalizedStringKey.sdkAsset("invalid_phone_or_password").toString()
                    } else if err.code == AuthErrorCodeResponse.AccountDeactivated {
                        errorMessage = LocalizedStringKey.sdkAsset("account_is_deleted").toString()
                    } else {
                        errorMessage = LocalizedStringKey.sdkAsset("unknown_error_message").toString()
                    }
                    onLoginFailure(err)
                case .finished:
                    break
                }
                
            }, receiveValue: { [weak self] data in
                guard let self else { return }
                debugPrint("✅ Login Facebook Success: \(data.accessToken)")
                self.completeLoginIfProfileReady(data)
            })
            .store(in: &cancellables)
    }
    
    func loginGoogle() {
        isLoading = true
        authManager.loginWithGoogleAccount()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
            
                switch completion {
                case .failure(let error):
                    debugPrint("❌ Google Error: \(error)")
                    let err = (error as? AuthErrorResponse) ?? .unknownError()
                    if err.code == AuthErrorCodeResponse.InvalidPhoneOrPassword {
                        errorMessage = LocalizedStringKey.sdkAsset("invalid_phone_or_password").toString()
                    } else if err.code == AuthErrorCodeResponse.AccountDeactivated {
                        errorMessage = LocalizedStringKey.sdkAsset("account_is_deleted").toString()
                    } else {
                        errorMessage = LocalizedStringKey.sdkAsset("unknown_error_message").toString()
                    }
                    self.onLoginFailure(err)
                case .finished:
                    break
                }
                
            }, receiveValue: { [weak self] data in
                guard let self else { return }
                debugPrint("✅ Login Google Success: \(data)")
                self.completeLoginIfProfileReady(data)
            })
            .store(in: &cancellables)
    }
    
    func loginViaApple() {
        isLoading = true
        authManager.loginWithAppleAccount()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
            
                switch completion {
                case .failure(let error):
                    debugPrint("❌ Apple Error: \(error)")
                    let err = (error as? AuthErrorResponse) ?? .unknownError()
                    if err.code == AuthErrorCodeResponse.InvalidPhoneOrPassword {
                        errorMessage = LocalizedStringKey.sdkAsset("invalid_phone_or_password").toString()
                    } else if err.code == AuthErrorCodeResponse.AccountDeactivated {
                        errorMessage = LocalizedStringKey.sdkAsset("account_is_deleted").toString()
                    } else {
                        errorMessage = LocalizedStringKey.sdkAsset("unknown_error_message").toString()
                    }
                    self.onLoginFailure(err)
                case .finished:
                    break
                }
                
            }, receiveValue: { [weak self] data in
                guard let self else { return }
                debugPrint("✅ Apple Google Success: \(data.accessToken)")
                self.completeLoginIfProfileReady(data)
            })
            .store(in: &cancellables)
    }
    
    func completeLoginIfProfileReady(_ data: AuthSessionResponse) {
        authSession = data
        if requiresProfileCompletion(data) {
            pendingLoginCompletionSession = data
            presentedScreen = .accountInfoConfirmation(session: data)
        } else {
            onLoginSuccess(data)
        }
    }

    func startProfileCompletion(isAtLeast16Confirmed: Bool) {
        guard let session = pendingLoginCompletionSession ?? authSession else { return }
        let phoneNumber = authManager.getPhoneNumber()
        guard phoneNumber.isValidPhoneNumber() else {
            presentedScreen = .postLoginPhoneNumberInput(
                session: session,
                isAtLeast16Confirmed: isAtLeast16Confirmed
            )
            return
        }
        presentedScreen = .postLoginPersonalInformation(
            session: session,
            phoneNumber: phoneNumber,
            isAtLeast16Confirmed: isAtLeast16Confirmed
        )
    }

    func finishProfileCompletion() {
        guard let session = pendingLoginCompletionSession ?? authSession else {
            presentedScreen = nil
            return
        }
        pendingLoginCompletionSession = nil
        presentedScreen = nil
        onLoginSuccess(session)
    }

    private func requiresProfileCompletion(_ data: AuthSessionResponse) -> Bool {
        data.isNewUser == true
    }

    func loginAsGuest() {
        isLoading = true
        authManager.loginWithGuest()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
            
                switch completion {
                case .failure(let error):
                    debugPrint("❌ Login with Guest Error: \(error)")
                    let err = (error as? AuthErrorResponse) ?? .unknownError()
                    if err.code == AuthErrorCodeResponse.InvalidPhoneOrPassword {
                        errorMessage = LocalizedStringKey.sdkAsset("invalid_phone_or_password").toString()
                    } else if err.code == AuthErrorCodeResponse.AccountDeactivated {
                        errorMessage = LocalizedStringKey.sdkAsset("can_not_play_now").toString()
                    } else {
                        errorMessage = LocalizedStringKey.sdkAsset("unknown_error_message").toString()
                    }
                    self.onLoginFailure(err)
                case .finished:
                    break
                }
                
            }, receiveValue: { [weak self] data in
                guard let self else { return }
                debugPrint("✅ Login with Guest Success: \(data)")
                self.authSession = data
//                startAutoLinkAccountLoop()
                self.onLoginSuccess(data)
//                presentedScreen = .linkAccount(guestToken: data.accessToken)
            })
            .store(in: &cancellables)
    }
//    
//    func refreshToken() {
//        isLoading = true
//        authManager.refreshToken()
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { [weak self] completion in
//                guard let self else { return }
//                self.isLoading = false
//            
//                switch completion {
//                case .failure(let error):
//                    debugPrint("❌ Refresh Token Error: \(error)")
////                    let description = getErrorDescription(from: error) ?? "Unknown error"
//                    let errorMessage = (error as? AuthErrorResponse)?.message ?? LocalizedStringKey.sdkAsset("unknown_error_message").toString()
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                        self.activeAlert = .loginFailed(errorMessage)
//                    }
//                case .finished:
//                    break
//                }
//                
//            }, receiveValue: { [weak self] data in
//                guard let self else { return }
//                debugPrint("✅ Refresh Token Success: \(data.accessToken)")
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                    let description: String = "GameUUID: \(data.gameUUID ?? "")\n AccessToken: \(data.accessToken) \n Refresh token: \(data.refreshToken) \n Expires: \(data.expireDate.toString(format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"))"
//                    
//                    self.activeAlert = .loginSuccess(description)
//                }
//            })
//            .store(in: &cancellables)
//    }
}
//
//extension WelcomeViewModel {
//    /// Call this once when you know `displayInfo` is set and isNewUser == true
//    func startAutoLinkAccountLoop() {
//        // reset & cancel any existing timer
//        timerCancellable?.cancel()
//        remainingSeconds = popupInterval
//        
//        // create a publisher that fires every 1s
//        timerCancellable = Timer
//            .publish(every: 1, on: .main, in: .common)
//            .autoconnect()
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                
//                // if they're no longer a guest, just reset the countdown
//                guard let info = self.authSession, info.isNewUser == false else {
//                    self.remainingSeconds = self.popupInterval
//                    return
//                }
//                
//                if self.remainingSeconds > 0 {
//                    self.remainingSeconds -= 1
//                    debugPrint("⏳ Link popup in \(self.remainingSeconds)s")
//                } else {
//                    // time’s up → show the popup
//                    debugPrint("🔔 Showing LinkAccountView now")
//                    self.presentedScreen = .linkAccount(guestToken: info.accessToken)
//                    // reset for next round
//                    self.remainingSeconds = self.popupInterval
//                }
//            }
//    }
//    
//    func stopAutoLinkAccountLoop() {
//        timerCancellable?.cancel()
//        timerCancellable = nil
//    }
//    
//    private func startAutoLinkLoop() {
//        autoLinkTask?.cancel()
//        autoLinkTask = Task { [weak self] in
//            guard let self = self else { return }
//            while !Task.isCancelled {
//                // Count down from `popupInterval` to 1, updating every second:
//                for sec in stride(from: popupInterval, through: 1, by: -1) {
//                    self.remainingSeconds = Int(sec)
//                    try? await Task.sleep(nanoseconds: 1_000_000_000)
//                }
//                // countdown done
//                self.remainingSeconds = 0
//                
//                // Only show if still a new user
//                if let info = self.authSession, info.isNewUser == true {
//                    self.presentedScreen = .linkAccount(guestToken: info.accessToken)
//                }
//                // Wait until they dismiss before looping again
//                await self.waitForDismiss()
//            }
//        }
//    }
//   
//    private func waitForDismiss() async {
//        while presentedScreen == .linkAccount(guestToken: authSession?.accessToken ?? "") {
//            try? await Task.sleep(nanoseconds: 100_000_000)
//        }
//    }
//    
//    func stopAutoLinkLoop() {
//        autoLinkTask?.cancel()
//        autoLinkTask = nil
//    }
//}
