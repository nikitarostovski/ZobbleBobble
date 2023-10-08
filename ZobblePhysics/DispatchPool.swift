//
//  DispatchPool.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 07.10.2023.
//

import Foundation

final class DispatchPool: ThreadPool {
    private let queue: OperationQueue
    let threadCount: Int
    
    init(threadCount: Int) {
        self.threadCount = threadCount
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = self.threadCount
        self.queue = queue
    }
    
    func addTask(_ task: @escaping ThreadPoolTask) {
        queue.addOperation {
            task()
        }
    }
    
    func waitForCompletion() {
        queue.waitUntilAllOperationsAreFinished()
    }
    
    func dispatch(_ elementCount: Int, callback: @escaping ThreadPoolCallback) {
        let batchSize = elementCount / threadCount
        for i in 0..<threadCount {
            let start = batchSize * i
            let end = start + batchSize
            
            addTask {
                callback(start, end)
            }
        }
        if batchSize * threadCount < elementCount {
            let start = batchSize * threadCount
            addTask {
                callback(start, elementCount)
            }
        }
        waitForCompletion()
    }
}
