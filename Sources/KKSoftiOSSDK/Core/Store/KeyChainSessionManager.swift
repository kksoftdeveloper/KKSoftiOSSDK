//
//  SecureStorage.swift
//  AuthSDK
//

import Foundation

public struct KeyChainSessionManager: SessionManager {
    
    private let service = "com.dar.kksoftiossdk.data.securestorage.session"
    private let account = "AuthSession"
    
    public init() {}
    
    public func saveSession(authSession: AuthSessionModel, isRefreshToken: Bool) throws {
        debugPrint("----> Saving session")
        let sessionData = try JSONEncoder().encode(authSession.toResponse())
        debugPrint("----> Saving session 2")
        print(String(data: sessionData, encoding: .utf8) ?? "Error converting to Data")
        try KeychainHelper.shared.save(sessionData, service: service, account: self.account)
        debugPrint("----> Saving session saved")
        if isRefreshToken {
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: NSNotification.Name(DefaultAuthManager.REFERSH_TOKEN_KEY), object: authSession.toResponse())
            debugPrint("----> Saving session refresh token posted")
        }
    }
    
    public func getSession() throws -> AuthSessionModel? {
        guard let data = try KeychainHelper.shared.load(service: service, account: self.account) else {
            return nil
        }
        return try JSONDecoder().decode(AuthSessionResponse.self, from: data).toModel()
        
    }
    
    public func clear() throws {
        try KeychainHelper.shared.delete(service: service, account: self.account)
    }
}
