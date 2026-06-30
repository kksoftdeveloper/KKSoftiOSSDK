//
//  GamePlayerInfoServerResponseDTO.swift
//  AuthSDK
//
//  Created by X on 5/8/25.
//

import Foundation

typealias GamePackageStatusResponse = APIResponse<GamePackageStatusDTO>
typealias GamePackagesResponse = APIResponse<GamePackagesDTO>

struct GamePackageStatusDTO: Decodable {
    
    let sku: String
    let status: String
    let price: Int
    let point: Int
    let alias: String?
    let description: String?
    
    private enum CodingKeys: String, CodingKey {
        case sku, status, price, point, alias, description
    }
}

extension GamePackageStatusDTO {
    func toModel() -> GamePackageStatusModel {
        return GamePackageStatusModel(sku: sku, status: status, price: price, point: point, alias: alias, description: description)
    }
}

struct GamePackagesDTO: Decodable {
    let content: [GamePackageStatusDTO]
    let pagination: PaginationDTO
    
    private enum CodingKeys: String, CodingKey {
        case content, pagination
    }
}

struct PaginationDTO: Decodable {
    let page: Int
    let totalPages: Int
    
    private enum CodingKeys: String, CodingKey {
        case page, totalPages
    }
}
