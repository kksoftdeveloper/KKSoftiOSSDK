//
//  IngameEventTracking.swift
//  TrackingSDK
//

import Foundation

public enum IngameEventTrackingConfigurator {
    private static var storedManager: TrackingManager?
    private static var hasInitialized = false
    
    @MainActor
    public static func configure(with manager: TrackingManager?) {
        storedManager = manager
        guard let manager else { return }
        if !hasInitialized {
            manager.initialize()
            hasInitialized = true
        }
        IngameEventTracking.manager = manager
    }
    
    static var currentManager: TrackingManager? {
        storedManager
    }
}

public enum IngameEventTracking {
    fileprivate static var manager: TrackingManager?
        
    // MARK: - Helpers
    private static func baseParams(gameUUID: String, characterId: String, characterName: String, serverId: Int, serverName: String) -> [String: Any] {
        var params: [String: Any] = [:]
        params["user_id"] = gameUUID
        params["character_id"] = characterId
        params["character_name"] = characterName
        params["server_id"] = serverId
        params["server_name"] = serverName
        if let carrier = manager?.getMobileCarrier(), !carrier.isEmpty {
            params["mobile_carrier"] = carrier
        }
        return params
    }

    private static func logDebug(_ message: String) {
        manager?.log(message)
        #if DEBUG
        print(message)
        #endif
    }
    
    static public func trackPlayGame(gameUUID: String, characterId: String, characterName: String, serverId: Int, serverName: String) {
        let params = baseParams(gameUUID: gameUUID, characterId: characterId, characterName: characterName, serverId: serverId, serverName: serverName)
        logDebug("[TrackingSDK] Play Game uid=\(gameUUID) character=\(characterId) characterName=\(characterName) server=\(serverId)")
        manager?.trackEvent(
            .playGame,
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_play_game",
                firebaseName: "fb_play_game",
                adjustToken: "1jp8w2",
                appsFlyerMutator: {
                    renameKey(&$0, from: "user_id", to: "af_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "af_character_id")
                    renameKey(&$0, from: "character_name", to: "af_character_name")
                    renameKey(&$0, from: "server_id", to: "af_server_id")
                    renameKey(&$0, from: "server_name", to: "af_server_name")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "mobile_carrier")
                    removeKey(&$0, key: "server_id")
                    removeKey(&$0, key: "server_name")
                    removeKey(&$0, key: "character_name")
                    renameKey(&$0, from: "character_id", to: "character")
                },
                adjustMutator: {
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "adj_character_id")
                    renameKey(&$0, from: "character_name", to: "adj_character_name")
                    renameKey(&$0, from: "server_id", to: "adj_server_id")
                    renameKey(&$0, from: "server_name", to: "adj_server_name")
                }
            )
        )
        logDebug("[TrackingSDK] Tracked play_game with params: \(params)")
    }
    
    static public func trackTutorialCompletedS1(gameUUID: String, characterId: String, characterName: String, serverId: Int, serverName: String) {
        let params = baseParams(gameUUID: gameUUID, characterId: characterId, characterName: characterName, serverId: serverId, serverName: serverName)
        logDebug("[TrackingSDK] Tutorial Completed S1 uid=\(gameUUID) character=\(characterId) characterName=\(characterName) server=\(serverId)")
        manager?.trackEvent(
            .tutorialCompletedS1,
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_tutorial_completed_s1",
                firebaseName: "fb_tutorial_completed_s1",
                adjustToken: "bua8q6",
                appsFlyerMutator: {
                    renameKey(&$0, from: "user_id", to: "af_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "af_character_id")
                    renameKey(&$0, from: "character_name", to: "af_character_name")
                    renameKey(&$0, from: "server_id", to: "af_server_id")
                    renameKey(&$0, from: "server_name", to: "af_server_name")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "mobile_carrier")
                    removeKey(&$0, key: "server_id")
                    removeKey(&$0, key: "server_name")
                    removeKey(&$0, key: "character_name")
                    renameKey(&$0, from: "character_id", to: "character")
                },
                adjustMutator: {
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "adj_character_id")
                    renameKey(&$0, from: "character_name", to: "adj_character_name")
                    renameKey(&$0, from: "server_id", to: "adj_server_id")
                    renameKey(&$0, from: "server_name", to: "adj_server_name")
                }
            )
        )
        logDebug("[TrackingSDK] Tracked tutorial_completed_s1 with params: \(params)")
    }
    
    // Mapping from Adjust level event name to Adjust token
    private static let adjustLevelTokenMap: [String: String] = [
        "adj_lev_10": "h6xgks",
        "adj_lev_20": "79tljf",
        "adj_lev_30": "1kdy8k",
        "adj_lev_40": "as8nww",
        "adj_lev_50": "n2ka53",
        "adj_lev_60": "p9ys08",
        "adj_lev_70": "ho51nh",
        "adj_lev_80": "qcvdov",
        "adj_lev_90": "4safrq",
        "adj_lev_100": "xakuf6"
    ]
    
    static public func trackLevelUp(level: Level, gameUUID: String, characterId: String, characterName: String, serverId: Int, serverName: String) {
        let params = baseParams(gameUUID: gameUUID, characterId: characterId, characterName: characterName, serverId: serverId, serverName: serverName)
        logDebug("[TrackingSDK] Level Up: level=\(level.rawValue) uid=\(gameUUID) character=\(characterId) characterName=\(characterName) server=\(serverId)")
        let adjustEventName = "adj_lev_\(level.rawValue)"
        let resolvedAdjustToken = adjustLevelTokenMap[adjustEventName]
        manager?.trackEvent(
            TrackingEvent.level.rawValue + "\(level.rawValue)",
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_lev_" + "\(level.rawValue)",
                firebaseName: "fb_lev_" + "\(level.rawValue)",
                adjustToken: resolvedAdjustToken,
                appsFlyerMutator: {
                    renameKey(&$0, from: "user_id", to: "af_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "af_character_id")
                    renameKey(&$0, from: "character_name", to: "af_character_name")
                    renameKey(&$0, from: "server_id", to: "af_server_id")
                    renameKey(&$0, from: "server_name", to: "af_server_name")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "mobile_carrier")
                    removeKey(&$0, key: "server_id")
                    removeKey(&$0, key: "server_name")
                    removeKey(&$0, key: "character_name")
                    renameKey(&$0, from: "character_id", to: "character")
                },
                adjustMutator: {
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "adj_character_id")
                    renameKey(&$0, from: "character_name", to: "adj_character_name")
                    renameKey(&$0, from: "server_id", to: "adj_server_id")
                    renameKey(&$0, from: "server_name", to: "adj_server_name")
                }
            )
        )
        logDebug("[TrackingSDK] Tracked level up with params: \(params)")
    }
    
    // Mapping from Adjust VIP level event name to Adjust token
    private static let adjustVIPLevelTokenMap: [String: String] = [
        "adj_vip_level_1": "o6lgmr",
        "adj_vip_level_2": "ru9kfu",
        "adj_vip_level_3": "b051gl",
        "adj_vip_level_4": "28bkr9",
        "adj_vip_level_5": "wsr9vq",
        "adj_vip_level_6": "h2op4p",
        "adj_vip_level_7": "fjovml",
        "adj_vip_level_8": "ihmwrk",
        "adj_vip_level_9": "kr82xp",
        "adj_vip_level_10": "cqupz5"
    ]
    
    static public func trackVIPLevel(level: VIPLevel, gameUUID: String, characterId: String, characterName: String, serverId: Int, serverName: String) {
        var params = baseParams(gameUUID: gameUUID, characterId: characterId, characterName: characterName, serverId: serverId, serverName: serverName)
        params["level"] = TrackingEvent.vipLevel.rawValue + "\(level.rawValue)"
        logDebug("[TrackingSDK] Vip Level: level=\(level.rawValue) uid=\(gameUUID) character=\(characterId) characterName=\(characterName) server=\(serverId)")
        let adjustVIPEventName = "adj_vip_level_\(level.rawValue)"
        let resolvedAdjustVIPToken = adjustVIPLevelTokenMap[adjustVIPEventName]
        manager?.trackEvent(
            TrackingEvent.vipLevel.rawValue + "\(level.rawValue)",
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_vip_level_" + "\(level.rawValue)",
                firebaseName: "fb_vip_level_" + "\(level.rawValue)",
                adjustToken: resolvedAdjustVIPToken,
                appsFlyerMutator: {
                    renameKey(&$0, from: "user_id", to: "af_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "af_character_id")
                    renameKey(&$0, from: "character_name", to: "af_character_name")
                    renameKey(&$0, from: "server_id", to: "af_server_id")
                    renameKey(&$0, from: "server_name", to: "af_server_name")
                    renameKey(&$0, from: "level", to: "af_level")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "mobile_carrier")
                    removeKey(&$0, key: "server_id")
                    removeKey(&$0, key: "server_name")
                    removeKey(&$0, key: "character_name")
                    renameKey(&$0, from: "character_id", to: "character")
                },
                adjustMutator: {
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "adj_character_id")
                    renameKey(&$0, from: "character_name", to: "adj_character_name")
                    renameKey(&$0, from: "server_id", to: "adj_server_id")
                    renameKey(&$0, from: "server_name", to: "adj_server_name")
                    renameKey(&$0, from: "level", to: "adj_level")
                }
            )
        )
        logDebug("[TrackingSDK] VIP Level with params: \(params)")
    }
    
    // Mapping from Adjust online time event name to Adjust token
    private static let adjustOnlineTimeTokenMap: [String: String] = [
        "adj_online_5mins": "jcsfj0",
        "adj_online_10mins": "qrsukz",
        "adj_online_30mins": "pe7hr4",
        "adj_online_60mins": "80mecf"
    ]
    
    static public func trackOnlineTime(time: OnlineTime, gameUUID: String, characterId: String, characterName: String, level: Level, serverId: Int, serverName: String) {
        var params = baseParams(gameUUID: gameUUID, characterId: characterId, characterName: characterName, serverId: serverId, serverName: serverName)
        params["level"] = TrackingEvent.vipLevel.rawValue + "\(level.rawValue)"
        logDebug("[TrackingSDK] Online Time: time=\(time.rawValue) uid=\(gameUUID) character=\(characterId) characterName=\(characterName) level=\(level.rawValue) server=\(serverId)")
        let adjustOnlineEventName = "adj_online_\(time.rawValue)mins"
        let resolvedAdjustOnlineToken = adjustOnlineTimeTokenMap[adjustOnlineEventName]
        manager?.trackEvent(
            TrackingEvent.onlineTime.rawValue + "\(time.rawValue)" + "mins",
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_online_" + "\(time.rawValue)" + "mins",
                firebaseName: "fb_online_" + "\(time.rawValue)" + "mins",
                adjustToken: resolvedAdjustOnlineToken,
                appsFlyerMutator: {
                    renameKey(&$0, from: "user_id", to: "af_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "af_character_id")
                    renameKey(&$0, from: "character_name", to: "af_character_name")
                    renameKey(&$0, from: "server_id", to: "af_server_id")
                    renameKey(&$0, from: "server_name", to: "af_server_name")
                    renameKey(&$0, from: "level", to: "af_level")
                },
                firebaseMutator: {
                    renameKey(&$0, from: "character_id", to: "character")
                    removeKey(&$0, key: "server_id")
                    removeKey(&$0, key: "server_name")
                    removeKey(&$0, key: "character_name")
                },
                adjustMutator: {
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                    renameKey(&$0, from: "character_id", to: "adj_character_id")
                    renameKey(&$0, from: "character_name", to: "adj_character_name")
                    renameKey(&$0, from: "server_id", to: "adj_server_id")
                    renameKey(&$0, from: "server_name", to: "adj_server_name")
                    renameKey(&$0, from: "level", to: "adj_level")
                }
            )
        )
        logDebug("[TrackingSDK] Tracked Online Time with params: \(params)")
    }

    private static func providerOverrides(
        appsFlyerName: String,
        firebaseName: String,
        adjustToken: String? = nil,
        appsFlyerMutator: ((inout [String: Any]) -> Void)? = nil,
        firebaseMutator: ((inout [String: Any]) -> Void)? = nil,
        adjustMutator: ((inout [String: Any]) -> Void)? = nil
    ) -> TrackingEventOverrides {
        var overrides: TrackingEventOverrides = [:]
        overrides[.appsFlyer] = ProviderEventOverride(
            eventName: appsFlyerName,
            parameterMutator: appsFlyerMutator
        )
        overrides[.firebaseAnalytics] = ProviderEventOverride(
            eventName: firebaseName,
            parameterMutator: firebaseMutator
        )
        if let adjustName = adjustToken {
            overrides[.adjust] = ProviderEventOverride(
                eventName: adjustName,
                parameterMutator: adjustMutator
            )
        }
        return overrides
    }
    
    private static func renameKey(_ params: inout [String: Any], from oldKey: String, to newKey: String) {
        guard let value = params.removeValue(forKey: oldKey) else { return }
        params[newKey] = value
    }

    private static func removeKey(_ params: inout [String: Any], key: String) {
        params.removeValue(forKey: key)
    }
}

