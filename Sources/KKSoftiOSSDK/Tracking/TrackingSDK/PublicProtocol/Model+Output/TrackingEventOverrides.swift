//
//  TrackingEventOverrides.swift
//  TrackingSDK
//
//  Created on 11/24/25.
//

import Foundation

/// Strategy used when combining override parameters with the base event payload.
public enum ProviderParameterStrategy {
    case merge   // merge base and override dictionaries (override wins on conflicts)
    case replace // ignore base parameters and use only override values
}

/// Allows per-provider customization of event names and parameters.
/// Use this to rename, add, or remove properties before dispatching to each provider.
public struct ProviderEventOverride {
    public let eventName: String?
    public let parameterStrategy: ProviderParameterStrategy
    public let parameters: [String: Any]?
    public let parameterMutator: ((inout [String: Any]) -> Void)?
    
    public init(
        eventName: String? = nil,
        parameterStrategy: ProviderParameterStrategy = .merge,
        parameters: [String: Any]? = nil,
        parameterMutator: ((inout [String: Any]) -> Void)? = nil
    ) {
        self.eventName = eventName
        self.parameterStrategy = parameterStrategy
        self.parameters = parameters
        self.parameterMutator = parameterMutator
    }
    
    func resolvedEventName(defaultName: String) -> String {
        eventName ?? defaultName
    }
    
    func resolvedParameters(base: [String: Any]?) -> [String: Any]? {
        let hasBase = (base?.isEmpty == false)
        let hasOverrides = (parameters?.isEmpty == false) || parameterStrategy == .replace || parameterMutator != nil
        
        guard hasBase || hasOverrides else {
            return nil
        }
        
        var output: [String: Any]
        switch parameterStrategy {
        case .merge:
            output = base ?? [:]
            if let params = parameters {
                params.forEach { output[$0.key] = $0.value }
            }
        case .replace:
            output = parameters ?? [:]
        }
        
        parameterMutator?(&output)
        return output
    }
}

/// Convenience alias for supplying per-provider overrides.
public typealias TrackingEventOverrides = [TrackingProviderKind: ProviderEventOverride]


