//
//  AppInfoStorage.swift
//  PaymentSDK
//
//  Created by X on 5/6/25.
//

import Foundation

protocol AppInfoStorage {
    var packageName: String? { get set }
    var appVersion: String? { get set }
    
    func clear()
}
