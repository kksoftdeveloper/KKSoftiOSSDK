//
//  APIError.swift
//  AuthSDK
//

enum APIError: Error {
    case invalidResponse
    case tokenExpired
    case refreshTokenExpired
    case unauthenticated
    case unknown
    case custom(String)
}
