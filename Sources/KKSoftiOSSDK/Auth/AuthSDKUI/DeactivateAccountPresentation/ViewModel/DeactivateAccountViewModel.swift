//
//  DeactivateAccountViewModel.swift
//  AuthSDK
//
//  Created by X on 6/19/25.
//

import Foundation

@MainActor
class DeactivateAccountViewModel: OpenViewModel {
    
    @Published private(set) var errorMessage: String?
    
    private var authManager: AuthManager
    private var onSuccess: (() -> Void)
    private var onFailure: (() -> Void)
    private let onClose: (() -> Void)
    
    @Published var isAcceptedTerm = false
    
    init(authManager: AuthManager,
         onSuccess: @escaping () -> Void,
         onFailure: @escaping () -> Void,
         onClose: @escaping () -> Void
    ) {
        self.authManager = authManager
        self.onClose = onClose
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
    
    func deactivateAccount() {
        isLoading = true
        authManager.deactivateAccount()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.isLoading = false
                    print("✅ Deactivate Account Failure")
                    self.onFailure()
                case .finished:
                    break
                }
            }, receiveValue: { _ in
                self.isLoading = false
                self.onSuccess()
                print("✅ Deactivate Account Success")
            })
            .store(in: &cancellables)
    }
}
