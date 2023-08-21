//
//  GUIRenderData.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation

struct GUIRenderData {
    struct ButtonModel {
        var backgroundColor: SIMD4<UInt8>
        var textColor: SIMD4<UInt8>
        var origin: SIMD2<Float>
        var size: SIMD2<Float>
        var foregroundPadding: SIMD2<Float> = SIMD2(36, 18)
        var textTextureIndex: Int32 = 0
    }
    
    struct LabelModel {
        var backgroundColor: SIMD4<UInt8>
        var textColor: SIMD4<UInt8>
        var origin: SIMD2<Float>
        var size: SIMD2<Float>
        var textTextureIndex: Int32 = 0
    }
    
    struct TextRenderData: Hashable {
        var text: String
        var fontName: String = "JoystixMonospace-Regular"
        var fontSize: Int = 36
        var textColor: SIMD4<UInt8> = .one

        init?(text: String?) {
            guard let text = text else { return nil }
            self.text = text
        }
    }
    
    var alpha: Float
    
    var textTexturesData: [TextRenderData?]
    
    let buttonCount: Int
    let buttons: UnsafeMutableRawPointer?
    
    let labelCount: Int
    let labels: UnsafeMutableRawPointer?
}
