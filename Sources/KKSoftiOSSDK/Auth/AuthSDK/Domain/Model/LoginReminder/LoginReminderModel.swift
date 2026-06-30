//
//  LoginReminderModel.swift
//  AuthSDK
//
//  Created by X on 5/1/25.
//

import Foundation


public struct LoginReminderModel {
    public let loginAfterSeconds: Int64
    public let isGuestUser: Bool
    public let isNewUser: Bool?
    
    public init(loginAfterSeconds: Int64, isGuestUser: Bool, isNewUser: Bool?) {
        self.loginAfterSeconds = loginAfterSeconds
        self.isGuestUser = isGuestUser
        self.isNewUser = isNewUser
    }
}

extension LoginReminderModel {
    func toResponse() -> LoginReminderResponse {
        return LoginReminderResponse(
            loginAfterSeconds: loginAfterSeconds,
            isGuestUser: isGuestUser,
            isNewUser: isNewUser
        )
    }
}
