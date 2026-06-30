//
//  OTPInputViewModel.swift
//  AuthSDK
//

import Foundation
import Combine
import SwiftUI

@MainActor
class OTPInputViewModel: OpenViewModel {
    
    let flow: FlowType
    let phoneNumber: String
    let otpSendableResponse: OTPSendableResponse
    let stepIndex: Int
    let totalStepCount: Int

    @Published var resendCountdown:  Int = 0
    @Published var otpExpireCountdown:  Int = 0
    @Published var isOTPRequestManyTime = false
    @Published var isNotAccountExisted  = false
    @Published var isOTPExpired         = false
    @Published var isOTPInvalid         = false
    @Published var isAccountExisted     = false
    @Published var errorMessage: LocalizedStringKey? = nil
    @Binding var presentedScreen: PopupScreen?
    @Published var isVerifyEnable: Bool = false
    @Published var otpText: String = "" {
        didSet {
            if otpText.count == 6 && isAccountExisted == false { isVerifyEnable = true } else { isVerifyEnable = false }
        }
    }

    private let authManager: AuthManager
    private let onSuccess: (String, String) -> Void
    private let onFailure: (AuthErrorResponse) -> Void

    private var resendCountdownTimer = CountdownTimer()
    private var otpExpireCountdownTimer = CountdownTimer()
    private var lastVerifiedOTP: String = ""
    
    public init(
      flowType: FlowType,
      phoneNumber: String,
      otpSendableResponse: OTPSendableResponse,
      stepIndex: Int = 2,
      totalStepCount: Int = 3,
      presentedScreen: Binding<PopupScreen?>,
      authManager: AuthManager,
      onSuccess: @escaping (String, String) -> Void = {_,_ in},
      onFailure: @escaping (AuthErrorResponse) -> Void = { _ in }
    ) {
        self.flow = flowType
        self.phoneNumber = phoneNumber
        self.otpSendableResponse = otpSendableResponse
        self.stepIndex = stepIndex
        self.totalStepCount = totalStepCount
        self._presentedScreen = presentedScreen
        self.authManager = authManager
        self.onSuccess   = onSuccess
        self.onFailure   = onFailure
        super.init()
        
        resendCountdownTimer.$remaining
            .assign(to: \.resendCountdown, on: self)
            .store(in: &cancellables)

        otpExpireCountdownTimer.$remaining
            .assign(to: \.otpExpireCountdown, on: self)
            .store(in: &cancellables)
        
        otpExpireCountdownTimer.expires = { [weak self] in
            self?.isOTPExpired = true
        }
        
        $otpText
            .receive(on: RunLoop.main)
            .sink { [weak self] otp in
                guard let self = self else { return }
                let isValid = otp.count == 6 && !self.isAccountExisted
                self.isVerifyEnable = isValid
                if isValid && otp != self.lastVerifiedOTP {
                    self.lastVerifiedOTP = otp
                    self.verifyOTP()
                }
            }
            .store(in: &cancellables)

    }

    func requestOTP() {
        resetState()
//        performRequest(
//            publisher: otpRequestPublisher(),
//            onSuccess: otpRequestSuccess
//        )
        otpRequestSuccess(otpSendableResponse)
    }

    func verifyOTP() {
        guard !isOTPExpired else {
            // expired before typing finished
            handleApiError(.otpExpired())
            return
        }
        resetState()
        performRequest(
            publisher: otpVerifyPublisher(code: otpText),
            onSuccess: otpVerifySuccess
        )
    }

    private func otpRequestPublisher() -> AnyPublisher<OTPSendableResponse, Error> {
        switch flow {
        case .register, .linkToNewAccount:
            return authManager.requestOTP(phone: phoneNumber)
        case .forgetPassword:
            return authManager.requestOTPForgetPassword(phone: phoneNumber)
        }
    }

    private func otpVerifyPublisher(code: String)
      -> AnyPublisher<OTPVerifiableResponse, Error>
    {
        switch flow {
        case .register, .linkToNewAccount:
            return authManager.verifyOTP(code: code)
        case .forgetPassword:
            return authManager.verifyOTPForgetPassword(
                phone: phoneNumber,
                code: code
            )
        }
    }

    private func performRequest<P: Publisher>(
      publisher: P,
      onSuccess: @escaping (P.Output) -> Void
    ) where P.Failure == Error {
        isLoading = true
        publisher
          .receive(on: DispatchQueue.main)
          .handleEvents(receiveCompletion: { [weak self] _ in
              self?.isLoading = false
          })
          .sink { [weak self] completion in
              if case .failure(let err) = completion {
                  self?.handleError(err)
              }
          } receiveValue: { output in
              onSuccess(output)
          }
          .store(in: &cancellables)
    }

    private func resetState() {
        isLoading             = false
        isOTPRequestManyTime  = false
        isNotAccountExisted   = false
        isOTPExpired          = false
        isOTPInvalid          = false
        isAccountExisted      = false
        errorMessage          = nil
    }
    
    private func resetOTPText() {
        otpText = ""
    }

    private func otpRequestSuccess(_ response: OTPSendableResponse) {
        resendCountdownTimer.start(from: response.retryAfterSeconds)
        otpExpireCountdownTimer.start(from: response.expiresInSeconds)
    }

    private func otpVerifySuccess(_ response: OTPVerifiableResponse) {
        if response.code != 200 {
            isOTPInvalid = true
            errorMessage = .sdkAsset("unknown_error_message")
            resetOTPText()
            onFailure(AuthErrorResponse.unknownError())
        } else {
            if let token = response.otpVerifiedToken {
                onSuccess(phoneNumber, token)
            }
        }
    }

    override func handleApiError(_ apiError: AuthErrorResponse) {
        switch apiError.code {
        case .AccountNotExist:
            resetOTPText()
            isNotAccountExisted = true
            errorMessage = apiError.displayMessage(serverFallback: .sdkAsset("otp_account_not_exist"))
        case .OTPExpired:
            resetOTPText()
            isOTPExpired = true
            errorMessage = apiError.displayMessage(serverFallback: .sdkAsset("otp_expired"))
        case .OTPRequestManyTime:
            resetOTPText()
            isOTPRequestManyTime = true
            errorMessage = apiError.displayMessage(serverFallback: .sdkAsset("otp_request_many_times"))
        case .OTPInvalid:
            resetOTPText()
            isOTPInvalid = true
            errorMessage = apiError.displayMessage(serverFallback: .sdkAsset("otp_invalid"))
        case .SocialAccountLinked:
            resetOTPText()
            isAccountExisted = true
            errorMessage = apiError.displayMessage(serverFallback: .sdkAsset("account_existed"))
        default:
            resetOTPText()
            super.handleApiError(apiError)
            errorMessage = apiError.displayMessage(serverFallback: .sdkAsset("unknown_error_message"))
        }
        onFailure(apiError)
    }

    override func handleGeneralError(_ error: Error) {
        resetOTPText()
        errorMessage = .sdkAsset("unknown_error_message")
        onFailure(.unknownError())
    }
}
