//
//  AccessToken.swift
//  Ghost
//
//  Created by Ilya Puchka on 22.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public struct AccessToken: JSONDecodable, APIResponseDecodable, CustomStringConvertible {
    public let type: String
    public let token: String
    public let refresh: String!
    public let expires: NSDate
    
    public init(type: String, token: String, refresh: String?, expires: NSDate) {
        self.type = type
        self.token = token
        self.refresh = refresh
        self.expires = expires
    }
    
    var requestHeaderValue: String {
        get {
            return "\(type) \(token)"
        }
    }
    
    func isNearToExpire() -> Bool {
        return expires.timeIntervalSinceNow < 60
    }
    
    func refreshTokenWithToken(refreshedToken: AccessToken) -> AccessToken {
        return AccessToken(type: refreshedToken.type, token: refreshedToken.token, refresh: self.refresh, expires: refreshedToken.expires)
    }
    
}

//MARK: - CustomStringConvertible
extension AccessToken {
    public var description: String {
        return "\(type) \(token) \(expires)"
    }
}

//MARK: - JSONDecodable
extension AccessToken {
    
    struct Keys {
        static let token    = "access_token"
        static let refresh  = "refresh_token"
        static let type     = "token_type"
        static let expires  = "expires_in"
    }
    public init?(jsonDictionary: JSONDictionary?) {
        guard
            let jsonDictionary  = jsonDictionary,
            let token           = jsonDictionary[Keys.token].string,
            let type            = jsonDictionary[Keys.type].string,
            let expires         = jsonDictionary[Keys.expires].double
            else {
                return nil
        }
        let refresh = jsonDictionary[Keys.refresh] as? String
        self.init(type: type, token: token, refresh: refresh, expires: NSDate(timeIntervalSinceNow: expires))
    }
}

//MARK: - APIResponseDecodable
extension AccessToken {
    
    public init?(apiResponseData: NSData) throws {
        guard let result: AccessToken = try apiResponseData.decodeToJSON() else {
            return nil
        }
        self = result
    }
}
