//
//  Environment.swift
//  AuthSDK
//
import Foundation

public enum Environment {
    case staging
    case production

    public static var current: Environment = .production

    public var baseURL: URL {
        switch self {
        case .staging:
            return URL(string: "https://api-staging.kksoft.vn")!
        case .production:
            return URL(string: "https://api.kksoft.vn")!
        }
    }
    
    public static var versionNumber: String {
        return getInfoValue(for: .versionNumber)
    }
    
    public static var deviceSecretKey: String {
        return getConfigValue(for: .deviceSecretKey)
    }
    
    public static var mixpanelKey: String {
        return getConfigValue(for: .mixpanelKey)
    }
    
    private static func getInfoValue(for key: ConfigKey) -> String {
        return Bundle.main.infoDictionary?[key.rawValue] as? String ?? ""
    }
    
    private static func getConfigValue(for key: ConfigKey) -> String {
        guard let url = Bundle.authSDK.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return ""
        }
        return dict[key.rawValue] as? String ?? ""
    }
}

enum ConfigKey: String {
    case versionNumber = "CFBundleShortVersionString"
    case deviceSecretKey = "DeviceSecretKey"
    case mixpanelKey = "MixpanelKey"
}
