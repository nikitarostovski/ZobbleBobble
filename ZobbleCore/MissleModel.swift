//
//  MissleModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

@propertyWrapper
public struct DecodableFloat {
    public var wrappedValue: CGFloat = 1
    
    public init() { }
}

extension DecodableFloat: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(CGFloat.self)
    }
}

public struct MissleModel: Codable {
    public let material: MaterialType
    public internal(set) var shape: ShapeModel
    @DecodableFloat public var startImpulse: CGFloat
}

extension KeyedDecodingContainer {
    func decode(_ type: DecodableFloat.Type, forKey key: Key) throws -> DecodableFloat {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}
