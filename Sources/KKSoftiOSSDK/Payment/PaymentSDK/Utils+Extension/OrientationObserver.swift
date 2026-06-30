//
//  OrientationObserver.swift
//  PaymentSDK
//
//  Created by X on 15/5/25.
//
import SwiftUI
import Combine

final class OrientationObserver: ObservableObject {
    @Published var isPortrait: Bool = true
    @Published var isLandscape: Bool = false
    
    private var cancellable: AnyCancellable?

    init() {
        updateOrientation()

        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateOrientation()
        }
    }

    private func updateOrientation() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        let orientation = scene.interfaceOrientation
        isPortrait = orientation.isPortrait
        isLandscape = orientation.isLandscape
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
