//
//  FacebookConfigServerResponseDTO.swift
//  AuthSDK
//

import Foundation

struct FacebookAccountServerDTO: Decodable {
    let clientId: String?
    let clientToken: String?
  
}

extension FacebookAccountServerDTO {
    
    func toModel() -> FacebookConfigModel {
        FacebookConfigModel(clientId: clientId, clientToken: clientToken)
    }
}
