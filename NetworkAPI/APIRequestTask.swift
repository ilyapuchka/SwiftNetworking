//
//  APIRequestTask.swift
//  Ghost
//
//  Created by Ilya Puchka on 16.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

final public class APIRequestTask: Task, Resumable, Cancellable, Equatable {
    
    public typealias TaskIdentifier = Int
    
    var onCancel: ((APIRequestTask, ErrorType?) -> ())?
    private var completionHandlers: [APIResponseDecodable -> Void] = []
    
    public func addCompletionHandler(handler: APIResponseDecodable -> Void) {
        completionHandlers.append(handler)
    }
    
    let session: NSURLSession
    let requestBuilder: () throws -> NSURLRequest
    
    private static var requestTasksCounter = 0
    
    init(request: APIRequestType, session: NSURLSession, requestBuilder: APIRequestType throws -> NSURLRequest) {
        self.taskIdentifier = ++APIRequestTask.requestTasksCounter
        self.session = session
        self.requestBuilder = { () throws -> NSURLRequest in
            return try requestBuilder(request)
        }
    }
    
    private(set) public var taskIdentifier: TaskIdentifier
    
    private var sessionTask: NSURLSessionTask!
    
    var originalRequest: NSURLRequest? {
        get {
            return sessionTask?.originalRequest
        }
    }
    
    func isTaskForSessionTask(task: NSURLSessionTask) -> Bool {
        if let sessionTask = sessionTask {
            return sessionTask === task
        }
        return false
    }
}

//MARK: - Resumable
extension APIRequestTask {
    func resume() {
        do {
            let httpRequest = try requestBuilder()
            sessionTask = self.session.dataTaskWithRequest(httpRequest)
            sessionTask.resume()
        }
        catch {
            cancel(error)
        }
    }
}

//MARK: - Cancellable
extension APIRequestTask {
    func cancel(error: ErrorType?) {
        if let sessionTask = sessionTask {
            sessionTask.cancel()
        }
        else {
            onCancel?(self, error)
            onCancel = nil
        }
    }
}

public func ==(left: APIRequestTask, right: APIRequestTask) -> Bool {
    return left.taskIdentifier == right.taskIdentifier
}