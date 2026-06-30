//
//  APIResponseError.swift
//  AuthSDK
//

import Foundation

struct APIResponseError: Decodable {
    let status: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case status, message
    }
}
