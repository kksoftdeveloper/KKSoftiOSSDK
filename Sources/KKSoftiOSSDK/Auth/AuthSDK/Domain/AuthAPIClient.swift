//
//  AuthAPIClient.swift
//  AuthSDK
//

import Foundation
import Combine

protocol AuthAPIClient {
    func initSDK(body: InitSDKRequestBody) -> AnyPublisher<AuthInitServerResponse, Error>
    
    func login(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<AuthSessionServerResponse, Error>
    
    func getGameServers(gameId: Int) -> AnyPublisher<GameServerInfoServerResponse, Error>
    
    func getGameServers(gameId: Int, header: [String: Any], body: [String: Any]) -> AnyPublisher<GameServerInfoServerResponse, Error>
    
    func updateGameServers(gameId: Int, serverId: Int, header: [String: Any]) -> AnyPublisher<GamePlayerInfoServerResponse, Error>
    
    func requestOTP(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<OTPSendableServerResponse, Error>
    
    func resendOTP(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<OTPResendableServerResponse, Error>
    
    func verifyOTP(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<OTPVerifiableServerResponse, Error>
    
    func phoneSignup(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<AuthSessionServerResponse, Error>
    
    func updateInfo(header: [String : Any]?, body: [String : Any]?) -> AnyPublisher<Bool, any Error> 
    
    func refreshToken(body: [String: Any]?) -> AnyPublisher<AuthSessionServerResponse, Error>
    
    func getCharacter(header: [String: Any], gameId: Int, serverId: Int) -> AnyPublisher<GameUUIDServerResponse, Error>
    
    func logout() -> AnyPublisher<DatalessServerResponse, Error>

    func forgetPassword(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<DatalessServerResponse, Error>
    
    func linkSocialAccount(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<AuthSessionServerResponse, Error>
    
    func linkToNewAccount(header: [String: Any]?, body: [String: Any]?) -> AnyPublisher<AuthSessionServerResponse, Error>
    
    func deactivateAccount(header: [String: Any]) -> AnyPublisher<DatalessServerResponse, Error>
}
