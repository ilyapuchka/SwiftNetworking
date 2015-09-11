//
//  APIResponse.swift
//  Ghost
//
//  Created by Ilya Puchka on 16.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol APIResponse {
    
    var httpResponse: NSHTTPURLResponse? {get}
    var data: NSData? {get}
    var error: ErrorType? {get}
    var originalRequest: NSURLRequest? {get}
    var contentType: HTTPContentType? {get}
    
}

public struct APIResponseOf<ResultType: APIResponseDecodable>: APIResponse {
    
    public let httpResponse: NSHTTPURLResponse?
    public let data: NSData?
    public let originalRequest: NSURLRequest?
    internal(set) public var error: ErrorType?
    internal(set) public var result: ResultType?
    
    init(request: NSURLRequest?, data: NSData?, httpResponse: NSURLResponse?, error: ErrorType?) {
        self.originalRequest = request
        self.httpResponse = httpResponse as? NSHTTPURLResponse
        self.data = data
        self.error = error
        self.result = nil
    }
    
    init(_ r: (request: NSURLRequest!, data: NSData!, httpResponse: NSURLResponse!, error: ErrorType!)) {
        self.init(request: r.request, data: r.data, httpResponse: r.httpResponse, error: r.error)
    }
    
    public var contentType: HTTPContentType? {
        get {
            return httpResponse?.MIMEType.flatMap {HTTPContentType(rawValue: $0)}
        }
    }
}

public struct None: APIResponseDecodable {
    public init?(apiResponseData: NSData) throws {
        return nil
    }
}
