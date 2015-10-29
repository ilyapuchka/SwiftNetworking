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
    
    public init?(_ value: JSONDictionary?) {
        if let value = value {
            self.init(value)
        }
        else {
            return nil
        }
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

extension String: JSONValue {}
extension IntegerLiteralType: JSONValue {}
extension FloatLiteralType: JSONValue {}
extension BooleanLiteralType: JSONValue {}
extension JSONArray: JSONValue {}

//MARK: - Subscript
extension JSONObject: DictionaryLiteralConvertible {
    
    public typealias Key = String
    public typealias Value = AnyObject
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(elements.reduce([:]) { (var r, i) in
            r[i.0] = i.1
            return r
        })
    }
    
    public subscript(keyPaths: String...) -> AnyObject? {
        return keyPath(keyPaths.joinWithSeparator("."))
    }
    
    public func keyPath<T: JSONDecodable>(keyPath: String) -> [T]? {
        if let jsonDict: [JSONDictionary] = self.keyPath(keyPath) {
            return jsonDict.flatMap { T(jsonDictionary: $0) }
        }
        return nil
    }

    public func keyPath<T: JSONDecodable>(keyPath: String) -> T? {
        if let jsonDict: JSONDictionary = self.keyPath(keyPath) {
            return T(jsonDictionary: jsonDict)
        }
        return nil
    }

    public func keyPath<T>(keyPath: String) -> T? {
        guard let paths = partitionKeyPath(keyPath) else { return nil }
        
        if paths.count == 1 {
            return value[keyPath] as? T
        }
        else {
            return resolve(paths) as? T
        }
    }
    
    private func partitionKeyPath(keyPath: String) -> [String]? {
        var paths = keyPath.componentsSeparatedByString(".")
        var key: String!
        var resolvedPaths = [String]()
        repeat {
            key = paths.removeFirst()
            if key.hasPrefix("@") && paths.count > 0 {
                key = "\(key).\(paths.removeFirst())"
            }
            resolvedPaths += [key]
        } while paths.count > 0
        return resolvedPaths
    }
    
    private func resolve(var keyPaths: [String]) -> AnyObject? {
        var result = value[keyPaths.removeFirst()]
        while keyPaths.count > 1 && result != nil {
            let key = keyPaths.removeFirst()
            result = resolve(key, value: result!)
        }
        if let result = result {
            return resolve(keyPaths.last!, value: result)
        }
        return nil
    }
    
    private func resolve(key: String, value: AnyObject) -> AnyObject? {
        if key.hasPrefix("@"), let array = value as? Array<AnyObject>  {
            return resolve(key, array: array)
        }
        else if value is JSONDictionary {
            return value[key]
        }
        return nil
    }
    
    private func resolve(key: String, array: Array<AnyObject>) -> AnyObject? {
        let startIndex = key.startIndex.advancedBy(1)
        let substring = key.substringFromIndex(startIndex)
        return CollectionOperation(substring).collect(array)
    }
    
    enum CollectionOperation {
        case Index(Int)
        case First
        case Last
        case KeyPath(String)
        
        init(_ rawValue: String) {
            switch rawValue {
            case _ where Int(rawValue) != nil:
                self = .Index(Int(rawValue)!)
            case "first":
                self = .First
            case "last":
                self = .Last
            default:
                self = .KeyPath(rawValue)
            }
        }
        
        func collect(array: Array<AnyObject>) -> AnyObject? {
            switch self {
            case .Index(let index):
                return array[index]
            case .First:
                return array.first
            case .Last:
                return array.last
            case .KeyPath(let keyPath):
                return (array as NSArray).valueForKeyPath("@\(keyPath)")
            }
        }
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
    public var String: Swift.String? {
        return self as? Swift.String
    }
    
    public var Double: Swift.Double? {
        return self as? Swift.Double
    }
    
    public var Int: Swift.Int? {
        return self as? Swift.Int
    }
    
    public var Array: [JSONDictionary]? {
        return self as? [JSONDictionary]
    }
    
    public var Object: JSONDictionary? {
        return self as? JSONDictionary
    }
}

