//
//  main.swift
//  LevelConverter
//
//  Created by Rost on 16.05.2023.
//

import Foundation
import Levels

let inputPath = URL(filePath: "/Users/rost/Dev/ZobbleBobble/LevelConverter")
let outputPath = URL(filePath: "/Users/rost/Dev/ZobbleBobble/Levels/Data")
let runPath = URL(filePath: FileManager.default.currentDirectoryPath)

let levelsFileName = "Levels"
var levelPacks: [PackModel] = []

do {
    let levelData = try Data(contentsOf: inputPath.appending(path: "\(levelsFileName).json"))
    levelPacks = try JSONDecoder().decode(Array<PackModel>.self, from: levelData)
} catch {
    throw error
}

var fileNames = [String]()
levelPacks.forEach { pack in
    pack.levels.forEach { level in
        level.initialChunks.forEach { chunk in
            if let source = chunk.source {
                fileNames.append(source)
            }
        }
        level.missleChunks.forEach { chunk in
            if let source = chunk.source {
                fileNames.append(source)
            }
        }
    }
}

let radius: CGFloat = 2
let scale: CGFloat = 1

fileNames = fileNames.removeDuplicates()

let particles = fileNames.compactMap { (s: String) -> (String, [ParticleModel])? in
    let url = inputPath.appending(path: "/Images/\(s).png")
    guard let sampler = ImageSampler(file: url) else { return nil }
    let particleStride: CGFloat = radius * 2 * 0.75
    
    let width = Int(CGFloat(sampler.width) * scale)
    let height = Int(CGFloat(sampler.height) * scale)
    let aabb = CGRect(x: 0, y: 0, width: width, height: height)
    
    var points = [CGPoint]()
    for y in stride(from: floor(aabb.minY / particleStride) * particleStride, to: aabb.maxY, by: particleStride) {
        for x in stride(from: floor(aabb.minX / particleStride) * particleStride, to: aabb.maxX, by: particleStride) {
            let point = CGPoint(x: x / aabb.width, y: y / aabb.height)
            points.append(point)
        }
    }
    let materials = sampler.getPixels(points)
    guard !materials.isEmpty else {
        return nil
    }
    var result = [ParticleModel]()
    
    var boundingRadius: CGFloat = 0
    
    var index = 0
    for y in stride(from: floor(aabb.minY / particleStride) * particleStride, to: aabb.maxY, by: particleStride) {
        for x in stride(from: floor(aabb.minX / particleStride) * particleStride, to: aabb.maxX, by: particleStride) {
            if let material = materials[index] {
                let point = CGPoint(x: x - aabb.width / 2, y: y - aabb.height / 2)
                let dist = sqrt(point.y * point.y + point.x * point.x)
                boundingRadius = max(boundingRadius, dist)
                let model = ParticleModel(position: point, material: material)
                result.append(model)
            }
            index += 1
        }
    }
    
    
    result = result.sorted(by: {
        let xp1 = $0.position.x / boundingRadius
        let xp2 = $1.position.x / boundingRadius
        return xp1 < xp2
    })
    
    return (s, result)
}

levelPacks = levelPacks.map { pack in
    var pack = pack
    pack.levels = pack.levels.map { level in
        var level = level
        level.initialChunks = level.initialChunks.map { chunk in
            var chunk = chunk
            if let particles = particles.first(where: { $0.0 == chunk.source })?.1 {
                chunk.setParticles(particles)
            }
            return chunk
        }
        level.missleChunks = level.missleChunks.map { chunk in
            var chunk = chunk
            if let particles = particles.first(where: { $0.0 == chunk.source })?.1 {
                chunk.setParticles(particles)
            }
            return chunk
        }
        return level
    }
    return pack
}

if let outputData = try? JSONEncoder().encode(levelPacks) {
    try outputData.write(to: outputPath.appending(path: "\(levelsFileName).json"))
}

