//
//  OpenViewModel.swift
//  AuthSDK
//
//  Created by X on 4/26/25.
//
import Foundation
import Combine


@MainActor
open class OpenViewModel: ObservableObject {
    
    @Published public var isLoading: Bool = false
    
    @Published public var viewError: ViewError?
    
    public var cancellables = Set<AnyCancellable>()
    
    
    public enum ViewError: Error, Identifiable {
        public var id: String {
            switch self {
            case .api(let api):     return "api:\(api.code.rawValue)"
            case .general(let err): return "general:\(String(describing: err))"
            }
        }
        
        case api(AuthErrorResponse)
        
        case general(Error)
    }
    
    public func handleError(_ error: Error) {
        if let apiErr = error as? AuthErrorResponse {
            handleApiError(apiErr)
        } else {
            handleGeneralError(error)
        }
    }
    
    open func handleApiError(_ apiError: AuthErrorResponse) {
        viewError = .api(apiError)
    }
    
    open func handleGeneralError(_ error: Error) {
        viewError = .general(error)
    }
}

