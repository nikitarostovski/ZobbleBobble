//
//  DecodableFloatWrapper.swift
//  ZobbleCore
//
//  Created by Rost on 13.05.2023.
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

extension KeyedDecodingContainer {
    func decode(_ type: DecodableFloat.Type, forKey key: Key) throws -> DecodableFloat {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}
