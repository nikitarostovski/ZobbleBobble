//
//  ShapeModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

public enum ShapeType: String, Codable {
    case circle
    case polygon
}

public struct ShapeModel: Codable {
    public let type: ShapeType
    public let radius: CGFloat?
    public let center: PointModel?
    public let points: [PointModel]?
    
    public let boundingRadius: CGFloat
    
    public var particleCenters: [CGPoint]
    public internal(set) var particleRadius: CGFloat {
        didSet {
            recalculateParticleCenters()
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(ShapeType.self, forKey: .type)
        self.radius = try container.decodeIfPresent(CGFloat.self, forKey: .radius)
        self.center = try container.decodeIfPresent(PointModel.self, forKey: .center)
        self.points = try container.decodeIfPresent([PointModel].self, forKey: .points)
        
        self.particleCenters = []
        self.particleRadius = 0
        
        switch type {
        case .circle:
            self.boundingRadius = self.radius ?? 0
        case .polygon:
            var maxX: CGFloat = 0
            var maxY: CGFloat = 0
            for p in self.points ?? [] {
                maxX = max(maxX, abs(p.x))
                maxY = max(maxY, abs(p.y))
            }
            self.boundingRadius = max(maxX, maxY)
        }
    }
    
    private mutating func recalculateParticleCenters() {
        let particleStride: CGFloat = particleRadius * 2 * 0.75
        
        var result = [CGPoint]()
        switch type {
        case .circle:
            guard let radius = radius, radius > .leastNonzeroMagnitude else { return }
            let center = center?.cgPointValue ?? .zero
            let aabb = CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius)
            
            for y in stride(from: floor(aabb.minY / particleStride) * particleStride, to: aabb.maxY, by: particleStride) {
                for x in stride(from: floor(aabb.minX / particleStride) * particleStride, to: aabb.maxX, by: particleStride) {
                    let point = CGPoint(x: x, y: y)
                    if point.distance(to: center) <= radius {
                        result.append(point)
                    }
                }
            }
        case .polygon:
            guard let points = points else { return }
            
            let polygon = points.map { $0.cgPointValue }
            let aabb = polygon.bounds
            
            for y in stride(from: floor(aabb.minY / particleStride) * particleStride, to: aabb.maxY, by: particleStride) {
                for x in stride(from: floor(aabb.minX / particleStride) * particleStride, to: aabb.maxX, by: particleStride) {
                    let point = CGPoint(x: x, y: y)
                    if aabb.contains(point) {
                        result.append(point)
                    }
                }
            }
        }
        self.particleCenters = result
    }
}

public struct PointModel: Codable {
    public let x, y: CGFloat
    
    public var cgPointValue: CGPoint {
        CGPoint(x: x, y: y)
    }
}
