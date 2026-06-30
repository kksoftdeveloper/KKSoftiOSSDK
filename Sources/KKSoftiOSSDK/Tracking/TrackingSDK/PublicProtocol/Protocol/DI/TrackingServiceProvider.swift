//
//  TrackingServiceProvider.swift
//  TrackingSDK
//
//  Created on 11/4/25.
//

import Foundation

/// Service provider for TrackingSDK
/// Provides a convenient way to configure and access tracking services
public final class TrackingServiceProvider {

    // MARK: - Properties

    public let trackingManager: TrackingManager

    // MARK: - Initialization

    private init(builder: Builder) {
        // Build tracking manager with configured providers
        let managerBuilder = DefaultTrackingManager.Builder()

        // Add tracking providers
        for provider in builder.trackingProviders {
            managerBuilder.addTrackingProvider(provider)
        }

        // Set crashlytics provider if provided
        if let crashlyticsProvider = builder.crashlyticsProvider {
            managerBuilder.setCrashlyticsProvider(crashlyticsProvider)
        }

        self.trackingManager = managerBuilder.build()
    }

    // MARK: - Builder

    public final class Builder {
        var trackingProviders: [TrackingProvider] = []
        var crashlyticsProvider: CrashlyticsProvider?

        // AppFlyers configuration
        var appFlyersAppID: String?
        var appFlyersDevKey: String?
        var enableAppFlyers: Bool = false

        // Firebase configuration (for future use)
        var firebaseAppID: String?
        var firebaseDevKey: String?
        var enableFirebaseAnalytics: Bool = false
        var isFirebaseCrashlyticsEnabled: Bool = false

        // Adjust configuration
        var adjustAppID: String?
        var adjustAppToken: String?
        var enableAdjust: Bool = false

        // TikTok configuration
        var tiktokAccessToken: String?
        var tiktokAppID: String?
        var tiktokBusinessAppID: String?
        var enableTikTok: Bool = false

        // Meta configuration
        var metaAppID: String?
        var metaClientToken: String?
        var enableMeta: Bool = false

        public init() {}

        // MARK: - AppFlyers Configuration

        /// Enable and configure AppFlyers
        /// - Parameters:
        ///   - appID: AppFlyers App ID
        ///   - devKey: AppFlyers Developer Key
        public func enableAppFlyers(appID: String, devKey: String) -> Builder {
            self.appFlyersAppID = appID
            self.appFlyersDevKey = devKey
            self.enableAppFlyers = true
            return self
        }

        // MARK: - Firebase Configuration (for future use)

        /// Enable and configure Firebase Analytics
        /// - Parameters:
        ///   - appID: Firebase App ID
        ///   - devKey: Firebase configuration key (optional)
        public func enableFirebaseAnalytics(appID: String, devKey: String? = nil) -> Builder {
            self.firebaseAppID = appID
            self.firebaseDevKey = devKey
            self.enableFirebaseAnalytics = true
            return self
        }

        /// Enable Firebase Crashlytics
        public func enableFirebaseCrashlytics() -> Builder {
            self.isFirebaseCrashlyticsEnabled = true
            return self
        }

        // MARK: - Adjust Configuration

        /// Enable and configure Adjust
        /// - Parameters:
        ///   - appID: Adjust App ID
        ///   - appToken: Adjust App Token (devKey)
        public func enableAdjust(appID: String, appToken: String) -> Builder {
            self.adjustAppID = appID
            self.adjustAppToken = appToken
            self.enableAdjust = true
            return self
        }

        // MARK: - TikTok Configuration

        /// Enable and configure TikTok App Events SDK.
        /// - Parameters:
        ///   - accessToken: TikTok access token from Events Manager.
        ///   - appID: iOS app identifier registered with TikTok.
        ///   - tiktokAppID: TikTok application identifier.
        public func enableTikTok(accessToken: String, appID: String, tiktokAppID: String) -> Builder {
            self.tiktokAccessToken = accessToken
            self.tiktokAppID = appID
            self.tiktokBusinessAppID = tiktokAppID
            self.enableTikTok = true
            return self
        }

        // MARK: - Meta Configuration

        /// Enable and configure Meta App Events SDK.
        /// - Parameters:
        ///   - appID: Meta application identifier.
        ///   - clientToken: Meta client token.
        public func enableMeta(appID: String, clientToken: String) -> Builder {
            self.metaAppID = appID
            self.metaClientToken = clientToken
            self.enableMeta = true
            return self
        }

        // MARK: - Custom Providers

        /// Add a custom tracking provider
        public func addTrackingProvider(_ provider: TrackingProvider) -> Builder {
            trackingProviders.append(provider)
            return self
        }

        /// Set a custom crashlytics provider
        public func setCrashlyticsProvider(_ provider: CrashlyticsProvider) -> Builder {
            self.crashlyticsProvider = provider
            return self
        }

        // MARK: - Build

        /// Build the TrackingServiceProvider
        public func build() -> TrackingServiceProvider {
            // Create AppFlyers provider if enabled
            if enableAppFlyers, let appID = appFlyersAppID, let devKey = appFlyersDevKey {
                let appFlyersProvider = AppFlyersProvider(appID: appID, devKey: devKey)
                trackingProviders.append(appFlyersProvider)
            }

            // Create Firebase Analytics provider if enabled (placeholder for now)
            if enableFirebaseAnalytics, let appID = firebaseAppID {
                let firebaseProvider = FirebaseAnalyticsProvider(appID: appID, devKey: firebaseDevKey ?? "")
                trackingProviders.append(firebaseProvider)
            }

            // Create Firebase Crashlytics provider if enabled (placeholder for now)
            if isFirebaseCrashlyticsEnabled {
                if crashlyticsProvider == nil {
                    crashlyticsProvider = FirebaseCrashlyticsProvider()
                }
            }

            // Create Adjust provider if enabled
            if enableAdjust, let appID = adjustAppID, let appToken = adjustAppToken {
                let adjustProvider = AdjustTrackingProvider(appID: appID, devKey: appToken)
                trackingProviders.append(adjustProvider)
            }

            // Create TikTok provider if enabled
            if enableTikTok,
               let accessToken = tiktokAccessToken,
               let appID = tiktokAppID,
               let tiktokAppID = tiktokBusinessAppID {
                let tiktokProvider = TikTokTrackingProvider(
                    accessToken: accessToken,
                    appID: appID,
                    tiktokAppID: tiktokAppID
                )
                trackingProviders.append(tiktokProvider)
            }

            // Create Meta provider if enabled
            if enableMeta, let appID = metaAppID, let clientToken = metaClientToken {
                let metaProvider = MetaTrackingProvider(appID: appID, clientToken: clientToken)
                trackingProviders.append(metaProvider)
            }

            return TrackingServiceProvider(builder: self)
        }
    }
}

