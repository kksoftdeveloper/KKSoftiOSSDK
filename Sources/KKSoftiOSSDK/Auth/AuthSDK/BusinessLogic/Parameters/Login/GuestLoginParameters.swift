//
//  GuestLoginParameters.swift
//  AuthSDK
//

import Foundation

struct GuestLoginParameters: ValidatedLoginParameters {
    let provider = "guest"
    let accessToken: String?

    enum CodingKeys: String, CodingKey {
        case provider
        case accessToken = "access_token"
    }

    func validate() throws {
        // e.g. if your API requires something else
        // or if accessToken must not be empty
        // Currently, it can be nil, so no real validation needed
    }
}
