//
//  PasswordInputViewModel.swift
//  AuthSDK
//

import Foundation
import Combine
import SwiftUI

@MainActor
class PasswordInputViewModel: OpenViewModel {
    
    public enum FocusField: Hashable {
        case password
        case confirmPassword
    }

    // MARK: Inputs
    let flowType: FlowType
    let phoneNumber: String
    let otpVerifiedToken: String
    let accountInformation: AccountInformation?
    let authManager: AuthManager
    let stepIndex: Int
    let totalStepCount: Int

    let onSuccess: (FlowType ,AuthSessionResponse?) -> Void
    let onFailure: (AuthErrorResponse) -> Void
    
    // MARK: Published state
    @Published var password         = ""
    @Published var confirmPassword  = ""
    @Published private(set) var isSubmitEnabled = false
    
    @Published var errorMessage: LocalizedStringKey? = nil
    
    @Binding var presentedScreen: PopupScreen?

    init(
      flowType: FlowType,
      phoneNumber: String,
      otpVerifiedToken: String,
      accountInformation: AccountInformation? = nil,
      stepIndex: Int = 3,
      totalStepCount: Int = 3,
      presentedScreen: Binding<PopupScreen?>,
      authManager: AuthManager,
      onSuccess: @escaping (FlowType ,AuthSessionResponse?) -> Void,
      onFailure: @escaping (AuthErrorResponse) -> Void
    ) {
        self.flowType        = flowType
        self.phoneNumber = phoneNumber
        self.otpVerifiedToken = otpVerifiedToken
        self.accountInformation = accountInformation
        self.stepIndex = stepIndex
        self.totalStepCount = totalStepCount
        self._presentedScreen = presentedScreen
        self.authManager = authManager
        self.onSuccess    = onSuccess
        self.onFailure    = onFailure
        super.init()
        bindValidation()
    }

    /// Called by your view when the user taps “Submit”
    func submit() {
        guard isSubmitEnabled else {
            // Local password‐match/strength failure
            handleGeneralError(AuthErrorResponse.passwordValidationError())
            return
        }

        let pub = makePublisherAndSuccessKey()

        performCall(
            publisher: pub,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }

    // MARK: - Internals

    private func bindValidation() {
        Publishers
                  .CombineLatest($password, $confirmPassword)
                  .map { pass, confirm in
                      pass.isStrongPassword() && pass == confirm
                  }
                  .removeDuplicates()
                  .assign(to: \.isSubmitEnabled, on: self)
                  .store(in: &cancellables)
    }

    private func makePublisherAndSuccessKey() -> AnyPublisher<Void,Error> {
        
        let publisher: AnyPublisher<Void, Error>

        switch flowType {
        case .register:
            publisher = authManager
                .signup(phoneNumber: phoneNumber,
                        password: password,
                        otpVerifiedToken: otpVerifiedToken)
                .flatMap { [weak self] session -> AnyPublisher<AuthSessionResponse, Error> in
                    guard let self, let accountInformation = self.accountInformation else {
                        return Just(session)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }

                    return self.authManager.updateAccountInfo(data: accountInformation)
                        .map { _ in session }
                        .eraseToAnyPublisher()
                }
                .receive(on: DispatchQueue.main)
                .map { [weak self] session in
                    guard let self else { return }
                    self.presentedScreen = nil
                    self.onSuccess(.register, session)
                }.eraseToAnyPublisher()

        case .linkToNewAccount:
            publisher = authManager
                .linkToNewAccount(phoneNumber: phoneNumber,
                                  password: password,
                                  otpVerifiedToken: otpVerifiedToken)
                .receive(on: DispatchQueue.main)
                .map { [weak self] session in
                    guard let self else { return }
                    self.presentedScreen = nil
                    self.onSuccess(.linkToNewAccount, session)
                }.eraseToAnyPublisher()

        case .forgetPassword:
            publisher = authManager
                .forgetPassword(phoneNumber: phoneNumber,
                                password: password,
                                otpVerifiedToken: otpVerifiedToken)
                .receive(on: DispatchQueue.main)
                .map { [weak self] DatalessServerResponse in
                    guard let self else { return }
                    self.presentedScreen = nil
                    print("forget password success \(DatalessServerResponse)")
                    self.onSuccess(.forgetPassword, nil)
                }.eraseToAnyPublisher()
        }

        return publisher
    }

    private func performCall(
        publisher: AnyPublisher<Void,Error>,
        onSuccess: @escaping (FlowType, AuthSessionResponse?) -> Void,
        onFailure: @escaping (AuthErrorResponse) -> Void
    ) {
        isLoading = true

        publisher
          .receive(on: DispatchQueue.main)
          .sink { [weak self] completion in
            guard let self = self else { return }
            self.isLoading = false
            if case let .failure(err) = completion {
                // delegate to OpenViewModel
                if let apiErr = err as? AuthErrorResponse {
                    self.handleApiError(apiErr)
                    onFailure(apiErr)
                } else {
                    self.handleGeneralError(err)
                    onFailure(.unknownError())
                }
            }
        } receiveValue: { [weak self] in
            guard let _ = self else { return }
        }
        .store(in: &cancellables)
    }
    
    override func handleApiError(_ apiError: AuthErrorResponse) {
        if apiError.code == .NewPassordRepeated {
            errorMessage = .sdkAsset("password_repeadted")
        } else if apiError.code == .OTPExpired {
            errorMessage = .sdkAsset("otp_expired_then_try_again")
        } else {
            handleGeneralError(apiError)
        }
    }
    
    override func handleGeneralError(_ error: any Error) {
        if let err = error as? AuthErrorResponse, err.code == .PasswordValidationError {
            errorMessage = LocalizedStringKey.sdkAsset("password_validation_error")
        } else {
            errorMessage = LocalizedStringKey.sdkAsset("unknown_error_message")
        }
    }
}
