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
    
    var renderData: RenderData? { get set }
    
    var uniqueMaterials: [MaterialType] { get }
}
