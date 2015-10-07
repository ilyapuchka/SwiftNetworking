//
//  JSON.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 16.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public typealias JSONDictionary = [String: AnyObject]

public protocol JSONDecodable {
    init?(jsonDictionary: JSONDictionary?)
}

public protocol JSONArrayConvertible: JSONDecodable, JSONEncodable {
    static var jsonArrayRootKey: String? {get}
}

public protocol JSONEncodable {
    var jsonDictionary: JSONDictionary { get }
}

public struct JSONObject: APIResponseDecodable, APIRequestDataEncodable {
    public let value: JSONDictionary
}

public struct JSONArray: APIResponseDecodable, APIRequestDataEncodable {
    public let value: [JSONDictionary]
}

public struct JSONArrayOf<T: JSONArrayConvertible>: APIResponseDecodable, APIRequestDataEncodable {
    public let value: [T]
    
    public init(_ value: [T]) {
        self.value = value
    }
}

//MARK: - APIResponseDecodable
extension JSONObject {
    
    public init?(apiResponseData: NSData) throws {
        guard let result = try apiResponseData.decodeToJSON().map({JSONObject(value: $0)}) else {
            return nil
        }
        self = result
    }
    
    subscript(keyPath: String) -> AnyObject? {
        var paths = keyPath.componentsSeparatedByString(".")
        if paths.count == 1 {
            return value[keyPath]
        }
        else {
            var result = value[paths.removeAtIndex(0)] as? JSONDictionary
            while paths.count > 1 && result != nil {
                result = result?[paths.removeAtIndex(0)] as? JSONDictionary
            }
            return result?[paths.last!]
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

extension JSONArray {
    
    public init?(apiResponseData: NSData) throws {
        guard let result = try apiResponseData.decodeToJSON().map({JSONArray(value: $0)}) else {
            return nil
        }
        self = result
    }
}

extension JSONArrayOf {
    
    public init?(apiResponseData: NSData) throws {
        var array: [JSONDictionary]
        if let key = T.jsonArrayRootKey {
            guard let jsonDictionary: JSONDictionary = try apiResponseData.decodeToJSON(),
                jsonArray = jsonDictionary[key] as? [JSONDictionary] else {
                    return nil
            }
            array = jsonArray
        }
        else {
            guard let jsonArray: [JSONDictionary] = try apiResponseData.decodeToJSON() else {
                    return nil
            }
            array = jsonArray
        }
        self = JSONArrayOf<T>(array.flatMap { T(jsonDictionary: $0) })
    }
}



//MARK: - APIRequestDataEncodable
extension JSONObject {
    public func encodeForAPIRequestData() throws -> NSData {
        return try encodeJSONDictionary(value)
    }
}

extension JSONArray {
    public func encodeForAPIRequestData() throws -> NSData {
        return try encodeJSONArray(value)
    }
}

extension JSONArrayOf {
    public func encodeForAPIRequestData() throws -> NSData {
        if let key = T.jsonArrayRootKey {
            return try encodeJSONDictionary([key: value.map({$0.jsonDictionary})])
        }
        else {
            return try encodeJSONArray(value.map({$0.jsonDictionary}))
        }
    }
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

//MARK: - NSData

extension NSData {

    public func decodeToJSON() throws -> JSONDictionary? {
        return try NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions()) as? JSONDictionary
    }

    public func decodeToJSON() throws -> AnyObject? {
        return try NSJSONSerialization.JSONObjectWithData(self, options: [.AllowFragments])
    }

    public func decodeToJSON() throws -> [JSONDictionary]? {
        return try NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions()) as? [JSONDictionary]
    }

    public func decodeToJSON<J: JSONDecodable>() throws -> J? {
        return try J(jsonDictionary: self.decodeToJSON())
    }

    public func decodeToJSON<J: JSONDecodable>() throws -> [J]? {
        let array: [JSONDictionary]? = try self.decodeToJSON()
        return array?.flatMap { J(jsonDictionary: $0) }
    }
    
}

extension JSONEncodable {
    public func encodeJSON() throws -> NSData {
        return try serializeJSON(self.jsonDictionary)
    }
}

public func encodeJSONDictionary(jsonDictionary: JSONDictionary) throws -> NSData {
    return try serializeJSON(jsonDictionary)
}

public func encodeJSONArray(jsonArray: [JSONDictionary]) throws -> NSData {
    return try serializeJSON(jsonArray)
}

public func encodeJSONObjectsArray(objects: [JSONEncodable]) throws -> NSData {
    return try serializeJSON(objects.map { $0.jsonDictionary })
}

private func serializeJSON(obj: AnyObject) throws -> NSData {
    return try NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions())
}

public let JSONHeaders = [HTTPHeader.ContentType(HTTPContentType.JSON), HTTPHeader.Accept([HTTPContentType.JSON])]


extension Optional {
    public var string: String? {
        return self as? String
    }
    
    public var double: Double? {
        return self as? Double
    }
    
    public var int: Int? {
        return self as? Int
    }
    
    public var array: [JSONDictionary]? {
        return self as? [JSONDictionary]
    }
    
    public var dict: JSONDictionary? {
        return self as? JSONDictionary
    }
}

