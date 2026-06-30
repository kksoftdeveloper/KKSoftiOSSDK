//
//  File.swift
//  AuthSDK
//

import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let status: Int
    let data: T
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case status, data, message
    }
}

public struct DataEmptynessServerResponse: Decodable { }

public extension DataEmptynessServerResponse {
    func toModel() -> DataEmptynessModel {
        return DataEmptynessModel()
    }
}

public struct DatalessServerResponse: Decodable {
    let status: Int
    let message: String
}

public extension DatalessServerResponse {
    func toModel() -> DatalessModel {
        return DatalessModel(
            status: status,
            message: message
        )
    }
}
