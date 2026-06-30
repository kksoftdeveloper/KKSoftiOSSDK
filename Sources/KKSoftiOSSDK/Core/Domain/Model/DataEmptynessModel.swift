//
//  DataEmptynessModel.swift
//  KKSoftiOSSDK
//
//  Created by KKSOFT on 10/6/26.
//

import Foundation

public struct DataEmptynessModel: Decodable { }

public extension DataEmptynessModel {
    
    func toResponse() -> DataEmptynessResponse{
        return DataEmptynessResponse()
    }
}
