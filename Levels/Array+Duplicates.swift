//
//  Array+Duplicates.swift
//  ZobbleBobble
//
//  Created by Rost on 14.05.2023.
//

import Foundation

extension Array where Element: Equatable {
    public func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        return result
    }
}
