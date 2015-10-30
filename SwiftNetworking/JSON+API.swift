//
//  JSON+API.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 29.10.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

extension JSONObject: APIResponseDecodable, APIRequestDataEncodable {
    
    public init?(apiResponseData: NSData) throws {
        self.init(try apiResponseData.decodeToJSON())
    }
    
    public func encodeForAPIRequestData() throws -> NSData {
        return try encodeJSONDictionary(value)
    }
    
}

extension JSONArray: APIResponseDecodable, APIRequestDataEncodable {
    
    public init?(apiResponseData: NSData) throws {
        self.init(try apiResponseData.decodeToJSON())
    }

    public func encodeForAPIRequestData() throws -> NSData {
        return try encodeJSONArray(value)
    }
    
}

extension JSONArrayOf: APIResponseDecodable, APIRequestDataEncodable {
    
    public init?(apiResponseData: NSData) throws {
        let jsonArray: [JSONDictionary]
        if let jsonArrayRootKey = T.itemsKey {
            guard let jsonDictionary: JSONDictionary = try apiResponseData.decodeToJSON(),
                _jsonArray = jsonDictionary[jsonArrayRootKey] as? [JSONDictionary] else {
                    return nil
            }
            jsonArray = _jsonArray
        }
        else {
            guard let _jsonArray: [JSONDictionary] = try apiResponseData.decodeToJSON() else {
                return nil
            }
            jsonArray = _jsonArray
        }
        self = JSONArrayOf<T>(jsonArray.flatMap { T(jsonDictionary: $0) })
    }

    public func encodeForAPIRequestData() throws -> NSData {
        if let jsonArrayRootKey = T.itemsKey {
            return try encodeJSONDictionary([jsonArrayRootKey: value.map({$0.jsonDictionary})])
        }
        else {
            return try encodeJSONArray(value.map({$0.jsonDictionary}))
        }
    }
    
}

public protocol JSONValue: APIResponseDecodable {}

extension JSONValue {
    
    public init?(apiResponseData: NSData) throws {
        guard let result: AnyObject = try apiResponseData.decodeToJSON() else {
            return nil
        }
        if let result = result as? Self {
            self = result
        }
        else {
            return nil
        }
    }
}

extension String: JSONValue {}
extension IntegerLiteralType: JSONValue {}
extension FloatLiteralType: JSONValue {}
extension BooleanLiteralType: JSONValue {}
extension JSONArray: JSONValue {}
extension JSONObject: JSONValue {}


public let JSONHeaders = [HTTPHeader.ContentType(HTTPContentType.JSON), HTTPHeader.Accept([HTTPContentType.JSON])]

