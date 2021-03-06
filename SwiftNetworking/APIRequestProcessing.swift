//
//  APIRequestProcessing.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 16.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol APIRequestProcessing {
    func processRequest(request: APIRequestType) throws -> NSMutableURLRequest
}

public func percentEncodedQueryString(query: APIRequestQuery) -> String? {
    let components = NSURLComponents()
    components.queryItems = NSURLQueryItem.queryItems(query)
    return components.percentEncodedQuery
}

extension NSURLQueryItem {
    static func queryItems(query: APIRequestQuery) -> [NSURLQueryItem]? {
        if query.count > 0 {
            return query.map { NSURLQueryItem(name: $0, value: $1) }
        }
        return nil
    }
}

/**
Process APIRequest and returns NSURLRequest.
*/
public class DefaultAPIRequestProcessing: APIRequestProcessing {

    public var defaultHeaders: [HTTPHeader]
    
    public init(defaultHeaders: [HTTPHeader] = []) {
        self.defaultHeaders = defaultHeaders
    }
    
    public func processRequest(request: APIRequestType) throws -> NSMutableURLRequest {
        let components = NSURLComponents(string: request.endpoint.path)!
        components.queryItems = NSURLQueryItem.queryItems(request.query)
        guard let url = components.URLRelativeToURL(request.baseURL) else {
            throw NSError(code: .BadRequest)
        }
        
        let httpRequest = NSMutableURLRequest(URL: url)
        httpRequest.HTTPMethod = request.endpoint.method.rawValue
        httpRequest.HTTPBody = request.body
        for header in defaultHeaders + request.headers {
            header.setRequestHeader(httpRequest)
        }
        return httpRequest
    }

}