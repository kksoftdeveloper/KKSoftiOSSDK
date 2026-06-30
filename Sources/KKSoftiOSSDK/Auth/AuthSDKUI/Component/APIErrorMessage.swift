import SwiftUI

extension AuthErrorResponse {
    var shouldUseServerFallbackMessage: Bool {
        switch code {
        case .UnknownError,
             .SDKNotInitialized,
             .SDKSignatureError,
             .SignatureError,
             .AppNotFound,
             .AppNotConfigured,
             .AppNotConfiguredGame,
             .AppNotConfiguredGameServer,
             .AppNotConfiguredFacebook,
             .AppNotConfiguredGoogle:
            return true
        default:
            return false
        }
    }

    func displayMessage(serverFallback: LocalizedStringKey) -> LocalizedStringKey {
        guard !shouldUseServerFallbackMessage else { return serverFallback }
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return serverFallback }
        return LocalizedStringKey(trimmedMessage)
    }
}
