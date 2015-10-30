//
//  Pagination.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 11.09.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol PaginationMetadata: JSONDecodable {
    var page: Int {get}
    var limit: Int {get}
    var pages: Int {get}

    init(page: Int, limit: Int, pages: Int)
}

extension PaginationMetadata {
    
    func nextPage() -> Self? {
        guard page < pages else { return nil }
        return Self(page: page+1, limit: limit, pages: pages)
    }
    
    func prevPage() -> Self? {
        guard page > 0 else { return nil }
        return Self(page: page-1, limit: limit, pages: pages)
    }
}

public protocol Pagination {
    
    var metadata: PaginationMetadataType? {get}
    typealias PaginationMetadataType: PaginationMetadata
    
    init(metadata: PaginationMetadataType?)
}

extension Pagination {
    
    public init(page: Int, limit: Int, pages: Int = 0) {
        self.init(metadata: PaginationMetadataType(page: page, limit: limit, pages: pages))
    }

    public func nextPage() -> Self? {
        guard let next = metadata?.nextPage() else { return nil }
        return Self(metadata: next)
    }
    
    public func prevPage() -> Self? {
        guard let prev = metadata?.prevPage() else { return nil }
        return Self(metadata: prev)
    }
}

public protocol AnyPagination: Pagination, JSONDecodable, APIResponseDecodable {
    typealias Element: JSONDecodable
    
    var items: [Element] {get}
    init(items: [Element], metadata: PaginationMetadataType?)
    
    static func paginationKey() -> String
    static func itemsKey() -> String
}

extension AnyPagination {
    
     public init?(jsonDictionary: JSONDictionary?) {
        guard let
            json = JSONObject(jsonDictionary),
            items: [Element] = json.keyPath(Self.itemsKey()),
            metadata: PaginationMetadataType = json.keyPath(Self.paginationKey())
            else {
                return nil
        }
        self.init(items: items, metadata: metadata)
    }
}

extension AnyPagination {
    public init?(apiResponseData: NSData) throws {
        guard let jsonDictionary: JSONDictionary = try apiResponseData.decodeToJSON() else {
            return nil
        }
        self.init(jsonDictionary: jsonDictionary)
    }
}

public struct PaginationOf<T: JSONDecodable, M: PaginationMetadata>: AnyPagination {
    
    public var items: [T]
    public var metadata: M?
    
    public init(items: [T] = [], metadata: M? = nil) {
        self.items = items
        self.metadata = metadata
    }
    
    public init(metadata: M?) {
        self.init(items: [], metadata: metadata)
    }
    
}

extension AnyPagination {
    public static func paginationKey() -> String {
        return "pagination"
    }
    
    public static func itemsKey() -> String {
        return "items"
    }
}

