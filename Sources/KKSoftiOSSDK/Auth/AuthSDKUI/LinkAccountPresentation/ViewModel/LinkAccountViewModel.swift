//
//  LinkAccountViewModel.swift
//  AuthSDK
//
//  Created by X on 4/21/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class LinkAccountViewModel: OpenViewModel {
    let authManager: AuthManager
    
    @Published var presentedScreen: PopupScreen?
    @Published var guestToken: String?
    @Published var errorMessageKey: LocalizedStringKey?
    
    private var onSuccess: ((AuthSessionResponse) -> Void)
    private var onFailure: ((AuthErrorResponse) -> Void)
    private var onClose: (() -> Void)
    
    init(authManager: AuthManager,
         guestToken: String,
//         presentedScreen: PopupScreen?,
         onSuccess: @escaping ((AuthSessionResponse) -> Void),
         onFailure: @escaping ((AuthErrorResponse) -> Void),
         onClose: @escaping (() -> Void)) {
        self.authManager = authManager
        self.guestToken = guestToken
        self.onClose = onClose
        self.onSuccess = onSuccess
        self.onFailure = onFailure
//        self.presentedScreen = presentedScreen
        super.init()
    }
    
    func linkToFacebookAccount() {
        isLoading = true
        resetState()
        authManager.linkToFacebookAccount()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    debugPrint("❌ Link Facebook Error: \(error)")
                    let errorMessage = (error as? AuthErrorResponse) ?? AuthErrorResponse.unknownError()
                    handleApiError(errorMessage)
                    self.onFailure(errorMessage)
                case .finished:
                    break
                }
                
            }, receiveValue: { [weak self] data in
                guard let self else { return }
                debugPrint("✅ Link Facebook Success: \(data.accessToken)")
                self.onSuccess(data)
            })
            .store(in: &cancellables)
        
    }
    
    func linkToGoogleAccount() {
        isLoading = true
        resetState()
        authManager.linkToGoogleAccount()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    debugPrint("❌ Link Google Error: \(error)")
                    let errorMessage = (error as? AuthErrorResponse) ?? AuthErrorResponse.unknownError()
                    handleApiError(errorMessage)
                    self.onFailure(errorMessage)
                case .finished:
                    break
                }
                
            }, receiveValue: { [weak self] data in
                guard let self else { return }
                debugPrint("✅ Link Google Success: \(data.accessToken)")
                self.onSuccess(data)
            })
            .store(in: &cancellables)
    }
    
    func updateAccountInfo() {
        isLoading = true
        resetState()
        authManager.linkToGoogleAccount()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    debugPrint("❌ Link Google Error: \(error)")
                    let errorMessage = (error as? AuthErrorResponse) ?? AuthErrorResponse.unknownError()
                    handleApiError(errorMessage)
                    self.onFailure(errorMessage)
                case .finished:
                    break
                }
                
            }, receiveValue: { [weak self] data in
                guard let self else { return }
                debugPrint("✅ Link Google Success: \(data.accessToken)")
                self.onSuccess(data)
            })
            .store(in: &cancellables)
    }
    
    override func handleApiError(_ apiError: AuthErrorResponse) {
        switch apiError.code {
        case .SocialAccountLinked:
            errorMessageKey = .sdkAsset("account_linked_already")
        default:
            errorMessageKey = .sdkAsset("unknown_error_message")
        }
    }
    
    private func resetState() {
        errorMessageKey = nil
    }
}
