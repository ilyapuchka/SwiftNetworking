//
//  PaginationOf.swift
//  NetworkAPI
//
//  Created by Ilya Puchka on 11.09.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public struct PaginationOf<T: JSONArrayConvertible>: JSONDecodable, APIResponseDecodable {
    public let items: [T]
    public let page: Int
    public let limit: Int
    public let pages: Int
    public let total: Int
    public let next: Int?
    public let prev: Int?
    
    private init(items:[T] = [], page: Int, limit: Int, pages: Int, total: Int, next: Int? = nil, prev: Int? = nil) {
        self.items = items
        self.page = page
        self.pages = pages
        self.limit = limit
        self.total = total
        self.next = next
        self.prev = prev
    }
    
    public init(page: Int, limit: Int) {
        self.init(page: page, limit: limit, pages: 0, total: 0)
    }
    
    public func nextPage() -> PaginationOf<T>? {
        if let next = next {
            return PaginationOf<T>(page: next, limit: limit, pages: pages, total: total)
        }
        return nil
    }
    
    public func prevPage() -> PaginationOf<T>? {
        if let prev = prev {
            return PaginationOf<T>(page: prev, limit: limit, pages: pages, total: total)
        }
        return nil
    }
}

struct PaginationKeys {
    private static let meta = "meta"
    private static let pagination = "pagination"
    private static let page = "page"
    private static let limit = "limit"
    private static let pages = "pages"
    private static let total = "total"
    private static let next = "next"
    private static let prev = "prev"
}

//MARK: - JSONDecodable
extension PaginationOf {
    
    public init?(jsonDictionary: JSONDictionary?) {
        guard let
            jsonDictionary = jsonDictionary,
            itemsArray = jsonDictionary[T.jsonArrayRootKey].array,
            meta = jsonDictionary[PaginationKeys.meta].dict,
            pagination = meta[PaginationKeys.pagination].dict,
            page = pagination[PaginationKeys.page].int,
            limit = pagination[PaginationKeys.limit].int,
            pages = pagination[PaginationKeys.pages].int,
            total = pagination[PaginationKeys.total].int else
        {
            return nil
        }
        
        let next = jsonDictionary[PaginationKeys.next].int
        let prev = jsonDictionary[PaginationKeys.prev].int
        let items = itemsArray.flatMap {T(jsonDictionary: $0)}
        self.init(items: items, page: page, limit: limit, pages: pages, total: total, next: next, prev: prev)
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

