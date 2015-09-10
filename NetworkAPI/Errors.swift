//
//  Errors.swift
//  Ghost
//
//  Created by Ilya Puchka on 16.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public let NetworkErrorDomain = "Network.Errors"

public enum NetworkErrorCode : Int {
    case UnknownError = 999
    case InvalidCredentials
    case InvalidUserName
    case InvalidPassword
    case Unauthorized
    case SerializationError
    case HTTPError
    case BackendError
    case InvalidResponse
    case BadRequest
}

extension NSError {
    
    public convenience init(code: NetworkErrorCode, userInfo dict: [NSObject : AnyObject]? = nil) {
        self.init(domain: NetworkErrorDomain, code: code.rawValue, userInfo: dict)
    }
    
    public static func errorWithUnderlyingError(error: NSError?, code: NetworkErrorCode) -> NSError {
        return NSError(code: code, userInfo: error != nil ? [NSUnderlyingErrorKey: error!] : nil)
    }

    static func backendError(statusCode: Int, data: NSData?) -> ErrorType? {
        switch statusCode {
        case 200..<300: return nil
        case 401: return NSError(code: .Unauthorized)
        default:
            var userInfo: [NSObject: AnyObject] = ["statusCode": statusCode]
            if let data = data, string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                userInfo["response"] = string
            }
            return NSError(code: .BackendError, userInfo: userInfo)
        }
    }
}


