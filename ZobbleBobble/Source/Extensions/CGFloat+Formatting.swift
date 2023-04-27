//
//  CGFloat+Formatting.swift
//  ZobbleBobble
//
//  Created by Rost on 19.04.2023.
//

import Foundation

extension CGFloat {
    var formatted: String {
        String(format: "%.3f", self)
    }
}
