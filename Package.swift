// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KKSoftiOSSDK",
    platforms: [.iOS("15.0")],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KKSoftiOSSDK",
            targets: ["KKSoftiOSSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "8.0.0"),
        .package(url: "https://github.com/facebook/facebook-ios-sdk.git", from: "18.0.0"),
        .package(url: "https://github.com/mixpanel/mixpanel-swift.git", from: "6.4.0"),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework.git", from: "6.15.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.5.0"),
        .package(url: "https://github.com/adjust/ios_sdk.git", from: "5.5.1"),
        .package(url: "https://github.com/tiktok/tiktok-business-ios-sdk.git", from: "1.6.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        
        .target(
            name: "KKSoftiOSSDK",
            dependencies: [
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "FacebookLogin", package: "facebook-ios-sdk"),
                .product(name: "FacebookCore", package: "facebook-ios-sdk"),
                .product(name: "Mixpanel", package: "mixpanel-swift"),
                .product(name: "AppsFlyerLib", package: "AppsFlyerFramework"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalyticsCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "AdjustSdk", package: "ios_sdk"),
                .product(name: "TikTokBusinessSDK", package: "tiktok-business-ios-sdk")
            ],
            path: "Sources/KKSoftiOSSDK",
            exclude: [
                "Resources/Info.plist"
            ],
            sources: [
                "Core",
                "Auth/AuthSDK",
                "Auth/AuthSDKUI",
                "Payment/PaymentSDK",
                "Payment/PaymentSDKUI",
                "Tracking/TrackingSDK"
            ],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("CoreTelephony")
            ]
        )
    ]
)
