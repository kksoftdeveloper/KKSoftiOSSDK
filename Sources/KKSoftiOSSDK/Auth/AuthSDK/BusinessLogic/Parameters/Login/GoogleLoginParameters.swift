//
//  GoogleLoginParameters.swift
//  AuthSDK
//

import Foundation

struct GoogleLoginParameters: ValidatedLoginParameters {
    let provider = "google"
    let clientID: String
    let clientURLSchema: String
    
    func validate() throws {
        guard !clientID.isEmpty else {
            throw ValidationError.googleClientIDMissing
        }
        guard !clientURLSchema.isEmpty else {
            throw ValidationError.googleSchemaURLMissing
        }
    }
}

extension GoogleLoginParameters {
    static func fromSensitiveData() throws -> GoogleLoginParameters {
        let infoDictionary = Bundle.main.infoDictionary
        let storedClientID = try SensitiveDataManager.shared.get(for: .googleClientID)
        let storedURLSchema = try SensitiveDataManager.shared.get(for: .googleURLSchema)

        guard let clientID = [storedClientID, infoDictionary?["GIDClientID"] as? String]
            .compactMap({ $0?.configuredValue })
            .first else {
            throw ValidationError.googleClientIDMissing
        }

        let configuredURLSchema = (infoDictionary?["GIDReversedClientID"] as? String)?.configuredValue
        guard let urlSchema = [storedURLSchema, configuredURLSchema, googleURLSchema(from: infoDictionary)]
            .compactMap({ $0?.configuredValue })
            .first else {
            throw ValidationError.googleSchemaURLMissing
        }

        return GoogleLoginParameters(clientID: clientID, clientURLSchema: urlSchema)
    }

    private static func googleURLSchema(from infoDictionary: [String: Any]?) -> String? {
        let urlTypes = infoDictionary?["CFBundleURLTypes"] as? [[String: Any]]
        let schemes = urlTypes?
            .compactMap { $0["CFBundleURLSchemes"] as? [String] }
            .flatMap { $0 }
        return schemes?.first(where: { $0.hasPrefix("com.googleusercontent.apps.") })
    }
}
