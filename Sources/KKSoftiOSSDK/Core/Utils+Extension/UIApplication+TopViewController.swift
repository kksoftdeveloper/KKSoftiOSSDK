import UIKit

extension UIApplication {
    var authSDKKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
    }

    var authSDKTopViewController: UIViewController? {
        topViewController(from: authSDKKeyWindow?.rootViewController)
    }

    private func topViewController(from base: UIViewController?) -> UIViewController? {
        if let presented = base?.presentedViewController {
            return topViewController(from: presented)
        }

        if let navigationController = base as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }

        if let tabBarController = base as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }

        return base
    }
}
