//
//  AuthInitServerResponse.swift
//  AuthSDK
//

import Foundation

typealias AuthInitServerResponse = APIResponse<AuthInitServerDTO>

struct AuthInitServerDTO: Decodable {
    let platform: String
    let gameInfoDTO: GameInfoServerResponseDTO?
    let facebookConfig: FacebookAccountServerDTO?
    let googleConfig: GoogleAccountServerDTO?
    let versionInfo: VersionInfoServerDTO?
    let guestLoginAfterSeconds: Int64?
    
    private enum CodingKeys: String, CodingKey {
        case platform
        case gameInfoDTO = "game"
        case facebookConfig = "facebook"
        case googleConfig = "google"
        case versionInfo
        case guestLoginAfterSeconds = "guestLoginAfterSeconds"
    }
}

extension AuthInitServerDTO {
   
    func toModel() -> AuthInitModel {
        return AuthInitModel(
            platform: platform,
            gameInfoModel: gameInfoDTO?.toModel(),
            facebookConfigModel: facebookConfig?.toModel(),
            googleConfigModel: googleConfig?.toModel(),
            versionInfoModel: versionInfo?.toModel(),
            guestLoginAfterSeconds: self.guestLoginAfterSeconds
        )
    }
}


