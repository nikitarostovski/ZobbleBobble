//
//  Body.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation
import Levels

protocol Body: AnyObject {
    associatedtype RenderData
    
    var renderData: RenderData? { get }
    
    var uniqueMaterials: [MaterialType] { get }
    
    var userInteractive: Bool { get }
    
    func onTouchDown()
    func onTouchUp()
}

extension Body {
    var uniqueMaterials: [MaterialType] { [] }
    
    func onTouchDown() { }
    func onTouchUp() { }
}
