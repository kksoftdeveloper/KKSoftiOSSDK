//
//  PaymentSDKInitResponse.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

typealias PaymentSDKInitResponse = APIResponse<PaymentSDKInitResponseDTO>

struct PaymentSDKInitResponseDTO: Decodable {
    let platform: String
    let gameInfoDTO: GameInfoResponse
    
    private enum CodingKeys: String, CodingKey {
        case platform
        case gameInfoDTO = "game"
    }
}

extension PaymentSDKInitResponseDTO {
    
    func toModel() -> PaymentSDKInitModel {
        return PaymentSDKInitModel(status: 1, message: "Success")
    }
    
    func toGameInfoModel() -> GameInfoModel {
        return gameInfoDTO.toModel()
    }
}
