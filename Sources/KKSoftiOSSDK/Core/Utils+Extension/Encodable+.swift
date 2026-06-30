//
//  File.swift
//  AuthSDK
//

import Foundation
internal import Mixpanel

extension Encodable {
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }
    
    func toDictionaryOptional() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let dict = jsonObject as? [String: Any] else {
            return nil
        }

        var stringDict: [String: String] = [:]
        for (key, value) in dict {
            stringDict[key] = String(describing: value)
        }

        return stringDict
    }
}

extension Dictionary where Key == String, Value == Any {
    
    func toMixpanelType() -> [String: MixpanelType] {
        var result: [String: MixpanelType] = [:]
        
        for (key, value) in self {
            switch value {
            case let v as MixpanelType:
                result[key] = v
                
            case let nestedDict as [String: Any]:
                result[key] = nestedDict.toMixpanelType()
                
            case let array as [Any]:
                let convertedArray = array.compactMap { element -> MixpanelType? in
                    if let elementAsMixpanelType = element as? MixpanelType {
                        return elementAsMixpanelType
                    } else if let nestedDict = element as? [String: Any] {
                        return nestedDict.toMixpanelType()
                    } else {
                        return nil
                    }
                }
                result[key] = convertedArray as MixpanelType
                
            default:
                // Unsupported type -> skip or log if you want
                continue
            }
        }
        
        return result
    }
}

