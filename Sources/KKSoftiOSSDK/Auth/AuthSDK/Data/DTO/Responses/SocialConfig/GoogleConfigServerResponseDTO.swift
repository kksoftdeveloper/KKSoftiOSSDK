//
//  GoogleConfigServerResponseDTO.swift
//  AuthSDK
//

import Foundation

struct GoogleAccountServerDTO: Decodable {
    let clientId: String?
    let platformUrlSchema: String?
}

extension GoogleAccountServerDTO {
    func toModel() -> GoogleConfigModel {
        GoogleConfigModel(clientId: clientId, platformUrlSchema: platformUrlSchema)
    }
}
