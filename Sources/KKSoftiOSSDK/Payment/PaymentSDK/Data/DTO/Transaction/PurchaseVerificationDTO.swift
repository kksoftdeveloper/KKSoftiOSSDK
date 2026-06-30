//
//  GamePlayerInfoServerResponseDTO.swift
//  AuthSDK
//
//  Created by X on 5/8/25.
//

import Foundation

typealias PurchaseVerificationResponse = APIResponse<PurchaseVerificationDTO>

struct PurchaseVerificationDTO: Decodable {
    
    let transactionCode: String
    let point: Int
    
    private enum CodingKeys: String, CodingKey {
        case transactionCode, point
    }
}

extension PurchaseVerificationDTO {
    func toModel() -> PurchaseVerificationModel {
        return PurchaseVerificationModel(transactionCode: transactionCode, point: point)
    }
}
