//
//  main.swift
//  LevelConverter
//
//  Created by Rost on 16.05.2023.
//

import Foundation
import Blueprints

let inputPath = "/Users/rost/Dev/ZobbleBobble/LevelConverter/Images"
let outputPath = URL(filePath: "/Users/rost/Dev/ZobbleBobble/ZobbleBobble/Resource/JSON")

let radius: CGFloat = 1.5
let planetScale: CGFloat = 1.5
let missleScale: CGFloat = 0.5

for (scale, folder) in [(missleScale, "Missles"), (planetScale, "Planets")] {
    let inputPath = inputPath.appending("/\(folder)")
    
    let files = (try? FileManager.default.contentsOfDirectory(atPath: inputPath)) ?? []
    let fileNames: [String] = files.filter { $0.hasSuffix(".png") }
    
    let chunks = fileNames.compactMap { (s: String) -> ChunkBlueprintModel? in
        let url = URL(fileURLWithPath: "\(inputPath)/\(s)")
        
        guard let sampler = ImageSampler(file: url) else { return nil }
        let particleStride: CGFloat = radius * 2 * 0.75
        
        let width = Int(CGFloat(sampler.width) * scale)
        let height = Int(CGFloat(sampler.height) * scale)
        let aabb = CGRect(x: 0, y: 0, width: width, height: height)
        
        var samplingPoints = [CGPoint]()
        var boundingRadius: CGFloat = 0
        
        for y in stride(from: floor(aabb.minY / particleStride) * particleStride, to: aabb.maxY, by: particleStride) {
            for x in stride(from: floor(aabb.minX / particleStride) * particleStride, to: aabb.maxX, by: particleStride) {
                let samplingPoint = CGPoint(x: x / aabb.width, y: y / aabb.height)
                samplingPoints.append(samplingPoint)
                
                let point = CGPoint(x: x - aabb.width / 2, y: y - aabb.height / 2)
                let dist = sqrt(point.y * point.y + point.x * point.x)
                boundingRadius = max(boundingRadius, dist)
            }
        }
        let getPointsByUniqueColors = sampler.getPointsByUniqueColors(samplingPoints)
        let groups = getPointsByUniqueColors.compactMap { (color, samplintPoints) -> ChunkBlueprintModel.FuzzyParticleGroup? in
            let possibleMaterials = MaterialCategory.possibleMaterialCategories(for: color)
            guard !possibleMaterials.isEmpty else { return nil }
            
            let positions = samplintPoints.map {
                let xConverted = (($0.x * aabb.width) - aabb.width / 2)
                let yConverted = (($0.y * aabb.height) - aabb.height / 2)
                return ParticleBlueprintModel(x: xConverted, y: yConverted)
            }
            return .init(positions: positions, possibleMaterialCategories: possibleMaterials)
        }
        guard !groups.isEmpty else { return nil }
        return ChunkBlueprintModel(particleGroups: groups, boundingRadius: boundingRadius)
    }
    
    if let outputData: Data = try? JSONEncoder().encode(chunks) {
        let path = outputPath.appending(path: "\(folder).json")
        try outputData.write(to: path)
    }
}

extension MaterialCategory {
    private static var colorDiffThreshold: Float { 0.8 }
    
    /// Returns material categories available for use in procedural generation for passed color
    public static func possibleMaterialCategories(for color: SIMD4<UInt8>) -> [MaterialCategory] {
        guard color.w > 0 else { return [] }
        
        let total: Float = sqrt(255 * 255 * 3)
        
        let materialsDiff: [(Float, MaterialCategory)] = MaterialCategory.allCases.compactMap {
            let rdiff = Int($0.color.x) - Int(color.x)
            let gdiff = Int($0.color.y) - Int(color.y)
            let bdiff = Int($0.color.z) - Int(color.z)
            
            let d = sqrt(Float(rdiff * rdiff + gdiff * gdiff + bdiff * bdiff))
            let p = d / total
            
            guard p < Self.colorDiffThreshold else { return nil }
            return (p, $0)
        }
        return materialsDiff.map { $0.1 }
    }
}
