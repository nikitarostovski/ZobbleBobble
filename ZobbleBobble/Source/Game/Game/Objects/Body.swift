//
//  Body.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation

protocol Body: AnyObject {
    associatedtype RenderData
    
    var renderData: RenderData? { get }
    
    var uniqueMaterials: [MaterialType] { get }
    
    var userInteractive: Bool { get }
}

extension Body {
    var uniqueMaterials: [MaterialType] { [] }
}
