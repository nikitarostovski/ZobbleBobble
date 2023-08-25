//
//  GUIRenderData.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation

struct GUIRenderData {
    struct ViewModel {
        static let viewTypeRect: Int32 = 0
        static let viewTypeText: Int32 = 1
        
        var viewType: Int32
        var backgroundColor: SIMD4<UInt8>
        var textColor: SIMD4<UInt8>?
        var origin: SIMD2<Float>
        var size: SIMD2<Float>
        var textTextureIndex: Int32? = nil
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
    
    let viewCount: Int
    let views: UnsafeMutableRawPointer?
}
