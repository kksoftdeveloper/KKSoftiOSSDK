//
//  AuthProvider.swift
//  AuthSDK
//

import Foundation

enum AuthProvider: String, CaseIterable, Identifiable {
    case username = "username"
    case google = "google"
    case apple = "apple"
    case facebook = "facebook"
    case otp = "otp"
    case guest = "guest"
    case unknown = "unknown"

    public var id: String { rawValue }
}
