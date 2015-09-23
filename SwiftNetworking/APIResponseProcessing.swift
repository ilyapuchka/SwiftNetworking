//
//  APIResponseProcessing.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 16.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol APIResponseProcessing {
    func processResponse<ResultType>(var response: APIResponseOf<ResultType>, request: APIRequestFor<ResultType>) -> APIResponseOf<ResultType>
}

/**
Process APIResponse and returns new APIResponse filled with error and decoded response object.
*/
public class DefaultAPIResponseProcessing: APIResponseProcessing {
    
    public func processResponse<ResultType>(var response: APIResponseOf<ResultType>, request: APIRequestFor<ResultType>) -> APIResponseOf<ResultType> {
        do {
            try validate(response, request: request)
            response.result = try decode(response, request: request)
        }
        catch {
            response.error = error
        }
        return response
    }
    
    final private func validate<ResultType>(response: APIResponseOf<ResultType>, request: APIRequestFor<ResultType>) throws {
        try validateError(response, request: request)
        try validateHTTPResponse(response, request: request)
        try validateStatusCode(response, request: request)
        try validateContentType(response, request: request)
    }
    
    final private func validateError<ResultType>(response: APIResponseOf<ResultType>, request: APIRequestFor<ResultType>) throws {
        if let error = response.error {
            throw error
        }
    }
    
    final private func validateHTTPResponse<ResultType>(response: APIResponseOf<ResultType>, request: APIRequestFor<ResultType>) throws {
        if response.httpResponse == nil {
            throw NSError(code: .InvalidResponse)
        }
    }
    
    final private func validateStatusCode<ResultType>(response: APIResponseOf<ResultType>, request: APIRequestFor<ResultType>) throws {
        if let error = NSError.backendError(response.httpResponse!.statusCode, data: response.data) {
            throw error
        }
    }
    
    final private func validateContentType<ResultType>(response: APIResponseOf<ResultType>, request: APIRequestFor<ResultType>) throws {
        if let contentType = response.contentType {
            for case let .Accept(acceptable) in request.headers {
                if !acceptable.contains({ $0 == contentType }) {
                    throw NSError(code: .InvalidResponse)
                }
            }
        }
    }
    
    final private func decode<ResultType>(response: APIResponseOf<ResultType>, request: APIRequestFor<ResultType>) throws -> ResultType? {
        if let data = response.data {
            return try ResultType(apiResponseData: data)
        }
        return nil
    }
    
    public init() {}
    
}
