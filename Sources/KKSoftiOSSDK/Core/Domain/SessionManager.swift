//
//  SessionManager.swift
//  AuthSDK
//

import Foundation

protocol SessionManager {
    func saveSession(authSession: AuthSessionModel, isRefreshToken: Bool) throws
    func getSession() throws -> AuthSessionModel?
    func clear() throws
}

