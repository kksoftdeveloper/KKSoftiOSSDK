import Foundation
import FirebaseCore
import FirebaseCrashlytics

/// Firebase Crashlytics implementation of CrashlyticsProvider
public final class FirebaseCrashlyticsProvider: CrashlyticsProvider {
    
    private var isInitialized = false
    
    public init() {}
    
    // MARK: - CrashlyticsProvider
    
    public func initialize() {
        guard !isInitialized else {
            print("[FirebaseCrashlyticsProvider] Already initialized")
            return
        }
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCrashlyticsCollectionEnabled(true)
        
        isInitialized = true
        print("[FirebaseCrashlyticsProvider] Initialized and crash reporting enabled")
    }
    
    public func log(_ message: String) {
        guard let crashlytics = resolveCrashlytics() else { return }
        crashlytics.log(message)
        print("[FirebaseCrashlyticsProvider] Logged message: \(message)")
    }
    
    public func setCustomValue(_ value: Any, forKey key: String) {
        guard let crashlytics = resolveCrashlytics() else { return }
        let sanitizedValue = sanitize(value)
        crashlytics.setCustomValue(sanitizedValue, forKey: key)
        print("[FirebaseCrashlyticsProvider] Set custom value for key \(key): \(sanitizedValue)")
    }
    
    public func setUserID(_ userID: String) {
        guard let crashlytics = resolveCrashlytics() else { return }
        crashlytics.setUserID(userID)
        print("[FirebaseCrashlyticsProvider] Set user ID: \(userID)")
    }
    
    public func recordError(_ error: Error) {
        guard let crashlytics = resolveCrashlytics() else { return }
        crashlytics.record(error: error)
        print("[FirebaseCrashlyticsProvider] Recorded error: \(error)")
    }
    
    public func recordException(name: String, reason: String, userInfo: [String: Any]?) {
        guard let crashlytics = resolveCrashlytics() else { return }
        let exceptionModel = ExceptionModel(name: name, reason: reason)
        if let userInfo = userInfo {
            let sanitizedInfo = sanitize(dictionary: userInfo)
            sanitizedInfo.forEach { key, value in
                crashlytics.setCustomValue(value, forKey: "exception_\(key)")
            }
        }
        crashlytics.record(exceptionModel: exceptionModel)
        print("[FirebaseCrashlyticsProvider] Recorded exception: \(name) reason: \(reason)")
    }
    
    // MARK: - Helpers
    
    private func resolveCrashlytics() -> Crashlytics? {
        guard isInitialized else {
            print("[FirebaseCrashlyticsProvider] Not initialized. Call initialize() first.")
            return nil
        }
        return Crashlytics.crashlytics()
    }
    
    private func sanitize(_ value: Any) -> Any {
        switch value {
        case let value as String:
            return value
        case let value as Int:
            return value
        case let value as Int8:
            return value
        case let value as Int16:
            return value
        case let value as Int32:
            return value
        case let value as Int64:
            return value
        case let value as UInt:
            return value
        case let value as UInt8:
            return value
        case let value as UInt16:
            return value
        case let value as UInt32:
            return value
        case let value as UInt64:
            return value
        case let value as Double:
            return value
        case let value as Float:
            return value
        case let value as Bool:
            return value
        case let value as NSNumber:
            return value
        default:
            return String(describing: value)
        }
    }
    
    private func sanitize(dictionary: [String: Any]) -> [String: Any] {
        var sanitized: [String: Any] = [:]
        for (key, value) in dictionary {
            sanitized[key] = sanitize(value)
        }
        return sanitized
    }
}

