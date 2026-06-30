//
//  LoginParameters.swift
//  AuthSDK
//

import Foundation

protocol LoginParameters: Encodable {
    var provider: String { get }
}
