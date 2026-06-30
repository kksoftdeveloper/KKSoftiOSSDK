//
//  SignUpParameters.swift
//  AuthSDK
//

import Foundation


protocol SignupParameters: Encodable {
    var provider: String { get }
}
