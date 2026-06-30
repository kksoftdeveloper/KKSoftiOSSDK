//
//  FacebookLoginParameters.swift
//  AuthSDK
//

import Foundation

struct FacebookLoginParameters: ValidatedLoginParameters {
    let provider = "facebook"
    let clientID: String
    let clientSecret: String
    
    func validate() throws {
        guard !clientID.isEmpty else {
            throw ValidationError.facebookClientIDMissing
        }
        guard !clientSecret.isEmpty else {
            throw ValidationError.facebookClientSecretMissing
        }
    }
}

extension FacebookLoginParameters {
    static func fromSensitiveData() throws -> FacebookLoginParameters {
        let infoDictionary = Bundle.main.infoDictionary
        let storedClientID = try SensitiveDataManager.shared.get(for: .facebookClientID)
        let storedClientSecret = try SensitiveDataManager.shared.get(for: .facebookClientSecret)

        guard let clientID = [storedClientID, infoDictionary?["FacebookAppID"] as? String]
            .compactMap({ $0?.configuredValue })
            .first else {
            throw ValidationError.facebookClientIDMissing
        }
        guard let clientSecret = [storedClientSecret, infoDictionary?["FacebookClientToken"] as? String]
            .compactMap({ $0?.configuredValue })
            .first else {
            throw ValidationError.facebookClientSecretMissing
        }

        return FacebookLoginParameters(clientID: clientID, clientSecret: clientSecret)
    }
}
