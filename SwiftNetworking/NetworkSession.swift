//
//  NetworkSession.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 16.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol NetworkSession: class {
    
    func scheduleRequest<ResultType>(request: APIRequestFor<ResultType>, after: [APIRequestTask], completionHandler: (APIResponseOf<ResultType> -> Void)?) -> APIRequestTask
    func cancelTasksDependentOnTask(task: APIRequestTask, error: ErrorType?)
    
    var credentialsStorage: APICredentialsStorage {get}
}

public class NetworkSessionImp: NSObject, NetworkSession, NSURLSessionDataDelegate {
    
    private typealias TaskCompletionHandler = (NSURLRequest!, NSData!, NSURLResponse!, ErrorType!) -> Void
    private typealias TaskIdentifier = APIRequestTask.TaskIdentifier
    
    private(set) public var session: NSURLSession!
    
    private var completionHandlers = [TaskIdentifier: TaskCompletionHandler]()
    private var recievedData = [TaskIdentifier: NSMutableData]()
    private let resultsQueue: dispatch_queue_t
    
    private var tasks = [APIRequestTask]()
    
    var accessToken: AccessToken? {
        get {
            return credentialsStorage.accessToken
        }
        set {
            credentialsStorage.accessToken = newValue
        }
    }
    
    private static let scheduler = TasksScheduler<APIRequestTask>(maxTasks: 0)
    let requestSigning: APIRequestSigning
    let requestProcessing: APIRequestProcessing
    let responseProcessing: APIResponseProcessing
    private(set) public var credentialsStorage: APICredentialsStorage
    
    private let privateQueue: dispatch_queue_t = dispatch_queue_create("NetworkSessionQueue", DISPATCH_QUEUE_SERIAL)

    public init(
        configuration: NSURLSessionConfiguration = NetworkSessionImp.foregroundSessionConfiguration(),
        resultsQueue: dispatch_queue_t = dispatch_get_main_queue(),
        requestProcessing: APIRequestProcessing = DefaultAPIRequestProcessing(),
        requestSigning: APIRequestSigning = DefaultAPIRequestSigning(),
        responseProcessing: APIResponseProcessing = DefaultAPIResponseProcessing(),
        credentialsStorage: APICredentialsStorage = APICredentialsStorageInMemory())
    {
        self.resultsQueue = resultsQueue
        self.requestSigning = requestSigning
        self.requestProcessing = requestProcessing
        self.responseProcessing = responseProcessing
        self.credentialsStorage = credentialsStorage
        super.init()
        self.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    public static func foregroundSessionConfiguration(additinalHeaders: [HTTPHeader] = []) -> NSURLSessionConfiguration {
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        configuration.HTTPAdditionalHeaders = [:]
        for header in additinalHeaders {
            configuration.HTTPAdditionalHeaders![header.key] = header.requestHeaderValue
        }
        return configuration
    }
    
    public func scheduleRequest<ResultType>(request: APIRequestFor<ResultType>, after: [APIRequestTask] = [], completionHandler: (APIResponseOf<ResultType> -> Void)?) -> APIRequestTask {
        var task: APIRequestTask!
        dispatch_sync(privateQueue) {
            task = APIRequestTask(request: request, session: self.session, requestBuilder: self.buildRequest)
            task.onCancel = self.taskCancelled
            self.tasks.append(task)
            self.completionHandlers[task.taskIdentifier] = self.completeRequest(request, withHandler: completionHandler)
            NetworkSessionImp.scheduler.enqueue(task, after: after)
        }
        return task
    }
    
    private func buildRequest(request: APIRequestType) throws -> NSURLRequest {
        let httpRequest: NSMutableURLRequest
        httpRequest = try self.requestProcessing.processRequest(request)
        if request.endpoint.signed {
            return try self.requestSigning.signRequest(httpRequest, storage: self.credentialsStorage)
        }
        return httpRequest
    }
    
    private func completeRequest<ResultType>(request: APIRequestFor<ResultType>, withHandler completionHandler: (APIResponseOf<ResultType> -> Void)?) -> TaskCompletionHandler {
        return { response in
            let apiResponse = self.responseProcessing.processResponse(APIResponseOf<ResultType>(response), request: request)
            
            if let token = apiResponse.result as? AccessToken {
                self.accessToken = self.accessToken?.refreshTokenWithToken(token) ?? token
            }
            
            dispatch_async(self.resultsQueue) {
                completionHandler?(apiResponse)
            }
        }
    }
    
    private func finishTask(sessionTask: NSURLSessionTask?, _ transportTask: APIRequestTask) {
        self.completionHandlers[transportTask.taskIdentifier] = nil
        if let sessionTask = sessionTask {
            self.recievedData[sessionTask.taskIdentifier] = nil
        }

        if let index = self.tasks.indexOf(transportTask) {
            self.tasks.removeAtIndex(index)
        }
        NetworkSessionImp.scheduler.nextTask(transportTask)
    }
    
    private func taskCancelled(task: APIRequestTask, error: ErrorType?) {
        dispatch_async(privateQueue) {
            let comletionHandler = self.completionHandlers[task.taskIdentifier]
            self.completionHandlers[task.taskIdentifier] = nil
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                comletionHandler?(task.originalRequest, nil, nil, error)
            })
            self.finishTask(nil, task)
        }
    }
    
    public func cancelTasksDependentOnTask(task: APIRequestTask, error: ErrorType?) {
        NetworkSessionImp.scheduler.cancelTasksDependentOnTask(task.taskIdentifier, error: error)
    }
}

//MARK: NSURLSession delegate
extension NetworkSessionImp {
    
    private func transportTaskCancelled(transportTask: APIRequestTask, error: NSError?) -> Bool {
        if let error = error, onCancel = transportTask.onCancel where
            error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                onCancel(transportTask, error)
                return true;
        }
        return false;
    }
    
    private func completeTask(task: NSURLSessionTask, transportTask: APIRequestTask, error: NSError?) {
        if let completionHandler = self.completionHandlers[transportTask.taskIdentifier] {
            let data = self.recievedData[task.taskIdentifier]
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(task.originalRequest, data, task.response, error)
            })
        }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        dispatch_async(privateQueue) {
            let taskData = self.recievedData[dataTask.taskIdentifier] ?? NSMutableData()
            taskData.appendData(data)
            self.recievedData[dataTask.taskIdentifier] = taskData
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        dispatch_async(privateQueue) {
            if let transportTask = self.tasks.filter({ $0.isTaskForSessionTask(task) }).first {
                if !self.transportTaskCancelled(transportTask, error: error) {
                    self.completeTask(task, transportTask: transportTask, error: error)
                }
                self.finishTask(task, transportTask)
            }
        }
    }
}
