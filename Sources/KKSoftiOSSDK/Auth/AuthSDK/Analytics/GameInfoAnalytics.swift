//
//  GameInfoAnalytics.swift
//  AuthSDK
//
//  Created by X on 5/13/25.
//

import Foundation
internal import Mixpanel

protocol GameInfoAnalytics: AnalyticsProperties {
    var getGameInfo: String { get }
    var getGameServers: String { get }
    var updateGameServer: String { get }
}

extension GameInfoAnalytics {
    var getGameInfo: String { "getGameInfo" }
    var getGameServers: String { "getGameServers" }
    var updateGameServer: String { "updateGameServer" }
}
