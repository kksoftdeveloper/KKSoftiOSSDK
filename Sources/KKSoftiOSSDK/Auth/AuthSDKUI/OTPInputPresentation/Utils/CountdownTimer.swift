//
//  CountdownTimer.swift
//  AuthSDK
//
//  Created by X on 4/26/25.
//

import Foundation
import Combine

final class CountdownTimer {
    @Published private(set) var remaining: Int = 0
    var expires: () -> Void = {}
    
    private var cancellable: AnyCancellable?
    
    func start(from seconds: Int) {
        remaining = seconds
        cancellable?.cancel()
        cancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remaining > 0 {
                    self.remaining -= 1
                }
                if self.remaining == 0 {
                    self.cancellable?.cancel()
                    self.expires()
                }
            }
    }
    
    func stop() {
        cancellable?.cancel()
    }
}
