//
//  AuthTracking.swift
//  AuthSDK
//

import Foundation

public enum AuthTrackingConfigurator {
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
        AuthTracking.manager = manager
    }
    
    public static var currentManager: TrackingManager? {
        storedManager
    }
}

enum AuthTracking {
    fileprivate static var manager: TrackingManager?
    
    static func logOpenLoginForm() {
        manager?.log("[AuthTracking] Open login form")
        manager?.trackEvent(
            .loginFormViewed,
            overrides: providerOverrides(
                appsFlyerName: "af_open_login_form",
                firebaseName: "fb_open_login_form",
                adjustToken: "1e1io4"
            )
        )
    }
    
    static func logLoginSuccess(method: String, session: AuthSessionResponse) {
        var params: [String: Any] = [
            "method": method,
            "mobile_carrier": manager?.getMobileCarrier() ?? ""
        ]
        if let gameUUID = session.gameUUID {
            params["user_id"] = gameUUID
            manager?.setUserID(gameUUID)
        }
        manager?.log("[AuthTracking] Login success via \(method)")
        manager?.trackEvent(
            .loginSuccess,
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_login",
                firebaseName: "fb_login",
                adjustToken: "b8xdaw",
                appsFlyerMutator: { renameKey(&$0, from: "user_id", to: "af_uid")
                    renameKey(&$0, from: "method", to: "af_login_method")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "mobile_carrier")
                },
                adjustMutator: {
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                    renameKey(&$0, from: "method", to: "adj_login_method")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                }
            )
        )
        handleRetentionD1IfNeeded(session: session)
    }
    
    static func logLoginFailure(method: String, error: Error) {
        var params: [String: Any] = [
            "method": method
        ]
        
        if let authError = error as? AuthErrorResponse {
            params["reason"] = authError.message
        } else {
            let nsError = error as NSError
            params["reason"] = nsError.localizedDescription
        }

        manager?.log("[AuthTracking] Login failure via \(method): \(String(describing: params["reason"]))")
        manager?.trackEvent(
            .loginFailure,
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_login_fail",
                firebaseName: "fb_login_fail",
                adjustToken: "8yfvn2",
                appsFlyerMutator: {
                    renameKey(&$0, from: "method", to: "af_login_method")
                    renameKey(&$0, from: "reason", to: "af_login_fail_reason")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "reason")
                },
                adjustMutator: {
                    renameKey(&$0, from: "method", to: "adj_login_method")
                    renameKey(&$0, from: "reason", to: "adj_login_fail_reason")
                }
            )
        )
        manager?.recordError(error)
    }
    
    static func logRegisterSuccess(method: String, session: AuthSessionResponse) {
        var params: [String: Any] = [
            "method": method,
            "mobile_carrier": manager?.getMobileCarrier() ?? ""
        ]
        if let gameUUID = session.gameUUID {
            params["user_id"] = gameUUID
            manager?.setUserID(gameUUID)
        }
        manager?.log("[AuthTracking] Registration success via \(method)")
        manager?.trackEvent(
            .registration,
            parameters: params,
            overrides: providerOverrides(
                appsFlyerName: "af_registration",
                firebaseName: "fb_registration",
                adjustToken: "hhl18h",
                appsFlyerMutator: {
                    renameKey(&$0, from: "method", to: "af_signup_method")
                    renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                    renameKey(&$0, from: "user_id", to: "af_uid")
                },
                firebaseMutator: {
                    removeKey(&$0, key: "mobile_carrier")
                },
                adjustMutator: {
                    renameKey(&$0, from: "method", to: "adj_signup_method")
                    renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                    renameKey(&$0, from: "user_id", to: "adj_uid")
                }
            )
        )
    }

    static func handleRetentionD1IfNeeded(session: AuthSessionResponse) {
        guard let userId = session.gameUUID else { return }

        let defaults = UserDefaults.standard
        let checkpointKey = "auth_retention_checkpoint_\(userId)"
        let now = Date()
        let calendar = Calendar.current
        
        guard let checkpointDate = defaults.object(forKey: checkpointKey) as? Date else {
            defaults.set(now, forKey: checkpointKey)
            return
        }

        let startOfCheckpoint2AMDay = checkpointDate.startOf2AMDay()
        let startOfNow2AMDay = now.startOf2AMDay()
        
        let daysBetween = calendar.dateComponents([.day], from: startOfCheckpoint2AMDay, to: startOfNow2AMDay).day ?? 0

        if daysBetween == 1 {
            let params: [String: Any] = [
                "user_id": userId,
                "retention_days": 1,
                "mobile_carrier": manager?.getMobileCarrier() ?? ""
            ]

            manager?.trackEvent(
                .retentionD1,
                parameters: params,
                overrides: providerOverrides(
                    appsFlyerName: "af_retention_d1",
                    firebaseName: "fb_retention_d1",
                    adjustToken: "575v9f",
                    appsFlyerMutator: {
                        renameKey(&$0, from: "user_id", to: "af_uid")
                        renameKey(&$0, from: "retention_days", to: "af_retention_days")
                        renameKey(&$0, from: "mobile_carrier", to: "af_mobile_carrier")
                    },
                    adjustMutator: {
                        renameKey(&$0, from: "user_id", to: "adj_uid")
                        renameKey(&$0, from: "retention_days", to: "adj_retention_days")
                        renameKey(&$0, from: "mobile_carrier", to: "adj_mobile_carrier")
                    }
                )
            )
            defaults.set(now, forKey: checkpointKey)
        } else if daysBetween > 1 {
            defaults.set(now, forKey: checkpointKey)
        }
    }
}

// MARK: - Provider Overrides
extension AuthTracking {
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
        if let adjustToken = adjustToken {
            overrides[.adjust] = ProviderEventOverride(
                eventName: adjustToken,
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

