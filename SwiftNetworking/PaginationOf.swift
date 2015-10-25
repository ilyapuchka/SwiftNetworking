//
//  PaginationOf.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 11.09.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol PaginationMetadata: JSONDecodable {
    var page: Int {get}
    var limit: Int {get}

    init(page: Int, limit: Int)
    func nextPage() -> Self?
    func prevPage() -> Self?
}

public struct PaginationOf<T: JSONArrayConvertible, M: PaginationMetadata>: JSONDecodable, APIResponseDecodable {
    public var items: [T]
    public var pagination: PaginationMetadata?
    
    private init(items: [T] = [], pagination: PaginationMetadata?) {
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
        guard let _ = T.jsonArrayRootKey else {
            fatalError("\(T.self) can not be used in PaginationOf as it returns nil from jsonArrayRootKey.")
        }
        guard let _ = T.paginationMetadataKey else {
            fatalError("\(T.self) can not be used in PaginationOf as it returns nil from paginationMetadataKey.")
        }
        
        guard let
            jsonDictionary = jsonDictionary,
            itemsArray = jsonDictionary[T.jsonArrayRootKey!].array,
            paginationMetadata = jsonDictionary[T.paginationMetadataKey!].dict
            else
        {
            return nil
        }
        
        let items = itemsArray.flatMap {T(jsonDictionary: $0)}
        let pagination = M(jsonDictionary: paginationMetadata)
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

