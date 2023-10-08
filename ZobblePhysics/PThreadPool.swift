//
//  ThreadService.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 07.10.2023.
//

import Foundation

struct ThreadIdentifier {
    var id: String
}

class ThreadParameter {
    var threadIdentifier: ThreadIdentifier
    weak var worker: Worker?
    
    init(threadIdentifier: ThreadIdentifier, worker: Worker?) {
        self.threadIdentifier = threadIdentifier
        self.worker = worker
    }
}

class TaskQueue {
    private typealias os_unfair_lock_t = UnsafeMutablePointer<os_unfair_lock_s>
    private var lock: os_unfair_lock_t
    
    private var tasks: [ThreadPoolTask] = []
    private var remainingTasks = 0
    
    init() {
        var lock: os_unfair_lock_t
        lock = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
        self.lock = lock
    }
    
    func addTask(_ task: @escaping ThreadPoolTask) {
        os_unfair_lock_lock(lock)
        tasks.append(task)
        remainingTasks += 1
        os_unfair_lock_unlock(lock)
    }
    
    func getTask() -> ThreadPoolTask? {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        
        guard !tasks.isEmpty else { return nil }
        return tasks.removeFirst()
    }
    
    static func wait() {
        pthread_yield_np()
    }

    func waitForCompletion() {
        while remainingTasks > 0 {
            Self.wait()
        }
    }
    
    func workDone() {
        os_unfair_lock_lock(lock)
        remainingTasks -= 1
        os_unfair_lock_unlock(lock)
    }
}

func threadedFunction(pointer: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
    let threadParameter = pointer.load(as: ThreadParameter.self)
    let worker = threadParameter.worker
    worker?.run()
    return nil
}

class Worker {
    let id: Int
    var task: (() -> Void)?
    var thread: pthread_t?
    var isRunning = true
    weak var queue: TaskQueue?
    
    init(queue: TaskQueue?, id: Int) {
        self.queue = queue
        self.id = id
        createThread()
    }
    
    func run() {
//        print("!!! worker \(id) is working")
        while isRunning, let queue = queue {
            task = queue.getTask()
            if let task = task {
                task()
                queue.workDone()
                self.task = nil
            } else {
                TaskQueue.wait()
            }
        }
    }
    
    func stop() {
        isRunning = false
        if let thread = thread {
            pthread_join(thread, nil)
        }
    }
    
    private func createThread() {
        var newThread: pthread_t? = nil
        
        let threadParameter = ThreadParameter(threadIdentifier: ThreadIdentifier(id: "ZobblePhysics.Thread_\(id)"), worker: self)
        let pThreadParameter = UnsafeMutablePointer<ThreadParameter>.allocate(capacity: 1)
        pThreadParameter.pointee = threadParameter
        let result = pthread_create(&newThread, nil, threadedFunction, pThreadParameter)
        
        if result != 0 {
            print("Error creating thread--")
            fatalError("Error creating thread")
        }
//        print("!!! Thread \"\(threadParameter.threadIdentifier.id)\" created")
        self.thread = newThread
    }
}

final class PThreadPool: ThreadPool {
    let threadCount: Int
    private var workers: [Worker]
    private var queue: TaskQueue
    
    init(threadCount: Int) {
        self.threadCount = threadCount
        
        let queue = TaskQueue()
        self.queue = queue
        
        self.workers = (0..<threadCount).map {
            Worker(queue: queue, id: $0)
        }
    }
    
    deinit {
        workers.forEach {
            $0.stop()
        }
    }
    
    func addTask(_ task: @escaping ThreadPoolTask) {
        queue.addTask(task)
    }
    
    func waitForCompletion() {
        queue.waitForCompletion()
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
