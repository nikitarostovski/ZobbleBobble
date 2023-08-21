//
//  MaterialCategory.swift
//  Blueprints
//
//  Created by Rost on 21.08.2023.
//

import Foundation

public struct MaterialCategory: OptionSet, Codable, CaseIterable {
    public static var allCases: [MaterialCategory] { [.solid, .liquid, .dust] }
    
    public let rawValue: Int
    
    public static let solid = Self.init(rawValue: 1 << 0)
    public static let liquid = Self.init(rawValue: 1 << 1)
    public static let dust = Self.init(rawValue: 1 << 2)
    
    public var color: SIMD4<UInt8> {
        switch rawValue {
        case Self.solid.rawValue: return Colors.Materials.solid
        case Self.liquid.rawValue: return Colors.Materials.liquid
        case Self.dust.rawValue: return Colors.Materials.dusty
        default: return .zero
        }
    }
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
