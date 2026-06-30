//
//  EmptyModel.swift
//  AuthSDK
//
//  Created by X on 4/30/25.
//

import Foundation



public struct DatalessModel: Decodable {
    let status: Int
    let message: String
}

public extension DatalessModel {
    
    func toResponse() -> DatalessServerResponse {
        return DatalessServerResponse(status: status, message: message)
        
    }
    
    func toOutput() -> DatalessOutput {
        return DatalessOutput(status: status, message: message)
        
    }
}
