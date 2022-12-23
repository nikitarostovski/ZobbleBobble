//
//  Node.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import MetalKit

protocol Mesh {
    var isVisible: Bool { get set }
    var vertexBuffers: [MTLBuffer] { get }
    var vertexCount: Int { get }
    var primitiveType: MTLPrimitiveType { get }
}
