//
//  ThreadPool.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 03.10.2023.
//

import Foundation

typealias ThreadPoolTask = () -> Void
typealias ThreadPoolCallback = (Int, Int) -> Void

protocol ThreadPool {
    var threadCount: Int { get }
    
    init(threadCount: Int)
    func addTask(_ task: @escaping ThreadPoolTask)
    func waitForCompletion()
    func dispatch(_ elementCount: Int, callback: @escaping ThreadPoolCallback)
}
