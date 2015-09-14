//
//  TasksScheduler.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 16.08.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol Task {
    typealias TaskIdentifier: Hashable
    var taskIdentifier: TaskIdentifier {get}
}

protocol Resumable {
    func resume()
}

protocol Cancellable {
    func cancel(error: ErrorType?)
}

typealias ResumableTask = protocol<Task, Resumable>

final class TasksScheduler<T: protocol<ResumableTask, Equatable>> {
    
    typealias TaskIdentifier = T.TaskIdentifier
    
    let maxTasks: Int
    
    init(maxTasks: Int) {
        self.maxTasks = maxTasks
    }
    
    var taskDependencies = [TaskIdentifier: [TaskIdentifier]]()
    var enqueuedTasks = [T]()
    var ongoingTasks = [T]()
    
    private let privateQueue: dispatch_queue_t = dispatch_queue_create("TasksSchedulerQueue", DISPATCH_QUEUE_SERIAL)
    
    func enqueue(task: T, after: [T] = []) {
        dispatch_async(privateQueue, {
            self.taskDependencies[task.taskIdentifier] = self.taskDependencies[task.taskIdentifier] ?? [] + after.map {$0.taskIdentifier}
            self.enqueuedTasks.append(task)
            self.nextTask()
        })
    }
    
    func canResumeTask(task: T!) -> Bool {
        if task == nil {
            return false
        }
        
        let dependencies = self.taskDependencies[task.taskIdentifier]!
        let enquedTasksIds = enqueuedTasks.map {$0.taskIdentifier}
        let ongoingTasksIds = ongoingTasks.map {$0.taskIdentifier}
        
        for dependency in dependencies {
            if enquedTasksIds.indexOf(dependency) != nil || ongoingTasksIds.indexOf(dependency) != nil {
                return false
            }
        }
        return true
    }
    
    func canResumeMoreTasks() -> Bool {
        return (self.ongoingTasks.count <= self.maxTasks || self.maxTasks == 0)
    }
    
    func nextTask(finished: T? = nil) {
        dispatch_async(privateQueue, {
            if let finished = finished, let finishedTaskIndex = self.ongoingTasks.indexOf(finished) {
                self.ongoingTasks.removeAtIndex(finishedTaskIndex)
            }
            var nextTask: T! = nil
            var taskIndex: Int = 0
            while self.canResumeMoreTasks() && taskIndex < self.enqueuedTasks.count {
                nextTask = self.enqueuedTasks[taskIndex]
                if self.canResumeTask(nextTask) {
                    self.enqueuedTasks.removeAtIndex(taskIndex)
                    self.ongoingTasks.append(nextTask)
                    nextTask.resume()
                }
                else {
                    taskIndex++
                }
            }
        })
    }
    
    func cancel(tasks: [T], error: ErrorType?) {
        for task in tasks {
            if let task = task as? Cancellable {
                task.cancel(error)
            }
        }
    }
    
    func cancelAll(error: ErrorType?) {
        dispatch_async(privateQueue, { () -> Void in
            let ongoing = self.ongoingTasks
            self.ongoingTasks.removeAll()
            self.cancel(ongoing, error: error)
            
            let enqueued = self.enqueuedTasks
            self.enqueuedTasks.removeAll()
            self.cancel(enqueued, error: error)
        })
    }
    
    func cancelTasksDependentOnTask(taskIdentifier: T.TaskIdentifier, error: ErrorType?) {
        dispatch_async(privateQueue) {
            var tasksToCancel = [T]()
            let ongoing = self.ongoingTasks
            for (taskIndex, task) in ongoing.enumerate() {
                if let dependencies = self.taskDependencies[task.taskIdentifier],
                    let _ = dependencies.indexOf(taskIdentifier) {
                        self.ongoingTasks.removeAtIndex(taskIndex)
                        tasksToCancel.append(task)
                }
            }
            let enqueued = self.enqueuedTasks
            for (taskIndex, task) in enqueued.enumerate() {
                if let dependencies = self.taskDependencies[task.taskIdentifier],
                    let _ = dependencies.indexOf(taskIdentifier) {
                        self.enqueuedTasks.removeAtIndex(taskIndex)
                        tasksToCancel.append(task)
                }
            }
            self.cancel(tasksToCancel, error: error)
        }
    }
    
}