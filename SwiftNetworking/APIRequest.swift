//
//  APIRequest.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 16.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case GET    = "GET"
    case POST   = "POST"
    case PUT    = "PUT"
    case DELETE = "DELETE"
}

public protocol Endpoint {
    var path: String {get}
    var signed: Bool {get}
    var method: HTTPMethod {get}
}

public typealias MIMEType = String

public enum HTTPContentType: RawRepresentable {

    case JSON
    case form
    case multipart(String)

    public typealias RawValue = MIMEType
    
    public init?(rawValue: HTTPContentType.RawValue) {
        switch rawValue {
        case "application/json": self = .JSON
        default: return nil
        }
    }
    
    public var rawValue: HTTPContentType.RawValue {
        switch self {
        case .JSON: return "application/json"
        case .form: return "application/x-www-form-urlencoded"
        case .multipart(let boundary): return "multipart/form-data; boundary=\(boundary)"
        }
    }
}

public enum HTTPHeader: Equatable {
    
    case ContentDisposition(String)
    case Accept([HTTPContentType])
    case ContentType(HTTPContentType)
    case Authorization(AccessToken)
    case Custom(String, String)
    
    public var key: String {
        switch self {
        case .ContentDisposition:
            return "Content-Disposition"
        case .Accept:
            return "Accept"
        case .ContentType:
            return "Content-Type"
        case .Authorization:
            return "Authorization"
        case .Custom(let key, _):
            return key
        }
    }
    
    public var requestHeaderValue: String {
        switch self {
        case .ContentDisposition(let disposition):
            return disposition
        case .Accept(let types):
            let typeStrings = types.map({$0.rawValue})
            return typeStrings.joinWithSeparator(", ")
        case .ContentType(let type):
            return type.rawValue
        case .Authorization(let token):
            return token.requestHeaderValue
        case .Custom(_, let value):
            return value
        }
    }
    
    public func setRequestHeader(request: NSMutableURLRequest) {
        request.setValue(requestHeaderValue, forHTTPHeaderField: key)
    }
}

//MARK: - Equatable

public func ==(lhs: HTTPHeader, rhs: HTTPHeader) -> Bool {
    return lhs.key == rhs.key && lhs.requestHeaderValue == rhs.requestHeaderValue
}

public protocol APIRequestDataEncodable {
    func encodeForAPIRequestData() throws -> NSData
}

public protocol APIResponseDecodable {
    init?(apiResponseData: NSData) throws
}

public typealias APIRequestQuery = [String: String]

public protocol APIRequestType {
    
    var body: NSData? {get}
    var endpoint: Endpoint {get}
    var baseURL: NSURL {get}
    var headers: [HTTPHeader] {get}
    var query: APIRequestQuery {get}
    
}

public struct APIRequestFor<ResultType: APIResponseDecodable>: APIRequestType {
    
    public let body: NSData?
    public let endpoint: Endpoint
    public let baseURL: NSURL
    public let headers: [HTTPHeader]
    public let query: APIRequestQuery

    public init(endpoint: Endpoint, baseURL: NSURL, query: APIRequestQuery = APIRequestQuery(), headers: [HTTPHeader] = []) {
        self.endpoint = endpoint
        self.baseURL = baseURL
        self.query = query
        self.headers = headers
        self.body = nil
    }

    public init(endpoint: Endpoint, baseURL: NSURL, input: APIRequestDataEncodable, query: APIRequestQuery = APIRequestQuery(), headers: [HTTPHeader] = []) throws {
        self.endpoint = endpoint
        self.baseURL = baseURL
        self.query = query
        self.headers = headers
        self.body = try input.encodeForAPIRequestData()
    }
    
    public init(endpoint: Endpoint, baseURL: NSURL, body: NSData, query: APIRequestQuery = APIRequestQuery(), headers: [HTTPHeader] = []) {
        self.endpoint = endpoint
        self.baseURL = baseURL
        self.query = query
        self.headers = headers
        self.body = body
    }

}

