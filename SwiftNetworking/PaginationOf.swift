//
//  PaginationOf.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 11.09.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol Paginatable: JSONArrayConvertible {
    static var paginationMetadataKey: String { get }
}

public protocol PaginationMetadata: JSONDecodable {
    var page: Int {get}
    var limit: Int {get}

    init(page: Int, limit: Int)
    func nextPage() -> Self?
    func prevPage() -> Self?
}

public struct PaginationOf<T: Paginatable, M: PaginationMetadata>: JSONDecodable, APIResponseDecodable {
    public var items: [T]
    public var pagination: M?
    
    private init(items: [T] = [], pagination: M?) {
        self.items = items
        self.pagination = pagination
    }
    
    public init(page: Int, limit: Int) {
        self.init(pagination: M(page: page, limit: limit))
    }
    
    public func nextPage() -> PaginationOf<T, M>? {
        if let nextPage = pagination?.nextPage() {
            return PaginationOf<T, M>(pagination: nextPage)
        }
        return nil
    }
    
    public func prevPage() -> PaginationOf<T, M>? {
        if let prevPage = pagination?.prevPage() {
            return PaginationOf<T, M>(pagination: prevPage)
        }
        return nil
    }
}

//MARK: - JSONDecodable
extension PaginationOf {
    
    public init?(jsonDictionary: JSONDictionary?) {
        guard let jsonArrayRootKey = T.jsonArrayRootKey else {
            fatalError("Paginatable resource should provide non-nil jsonArrayRootKey.")
        }
        
        guard let
            json = JSONObject(jsonDictionary),
            items: [T] = json.keyPath(jsonArrayRootKey),
            pagination: M = json.keyPath(T.paginationMetadataKey)
        else {
            return nil
        }
        self.init(items: items, pagination: pagination)
    }
}

//MARK: - APIResponseDecodable
extension PaginationOf {
    public init?(apiResponseData: NSData) throws {
        guard let jsonDictionary: JSONDictionary = try apiResponseData.decodeToJSON() else {
            return nil
        }
        self.init(jsonDictionary: jsonDictionary)
    }
}

