//
//  MonoThreadPool.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 09.10.2023.
//

import Foundation

final class MonoThreadPool: ThreadPool {
    let threadCount: Int = 1
    
    init(threadCount: Int) { }
    
    func addTask(_ task: @escaping ThreadPoolTask) {
        task()
    }
    
    func waitForCompletion() { }
    
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
