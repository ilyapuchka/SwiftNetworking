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

public protocol JSONConvertible: JSONDecodable, JSONEncodable {}

public protocol JSONArrayConvertible: JSONConvertible {
    //having nil is a workround for but with extensions rdar://23314307
    //when it's fixed there should be extension of JSONArrayOf where T: JSONArrayConvertible
    static var jsonArrayRootKey: String? { get }
}

public protocol JSONEncodable {
    var jsonDictionary: JSONDictionary { get }
}

public struct JSONObject {
    public let value: JSONDictionary
    
    public init(_ value: JSONDictionary) {
        self.value = value
    }
}

public struct JSONArray {
    public let value: [JSONDictionary]
}

public struct JSONArrayOf<T: JSONArrayConvertible> {
    public let value: [T]
    
    public init(_ value: [T]) {
        self.value = value
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

