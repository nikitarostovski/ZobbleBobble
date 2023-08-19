//
//  GunBody.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation
import Levels

class GunBody: Body {
    struct State {
        var visibleMaterials = [MaterialRenderData]()
        var currentContainerIndex: CGFloat = 0
        var currentMissleIndex: CGFloat = 0
        var visibleMissleRange: ClosedRange<CGFloat> = 0...0
    }
    
    var userInteractive: Bool = false
    var renderData: StarRenderData?
    
    var player: PlayerModel
    var state = State()
    
    private let initialMaterials: [MaterialRenderData]
    
    var selectedContainer: ContainerModel? { player.selectedContainer }
    
    var selectedMissle: ChunkModel? {
        let index = Int(state.currentMissleIndex)
        guard let selectedContainer = selectedContainer, 0..<selectedContainer.missles.count ~= index else { return nil }
        return selectedContainer.missles[index]
    }
    
    var position = SIMD2<Float>(0, 0)
    var radius: Float
    var missleRadius: Float
    var mainColor: SIMD4<UInt8>
    
    private(set) var renderCenter = SIMD2<Float>(0, 0)
    private(set) var missleCenter = SIMD2<Float>(0, 0)
    
    init(player: PlayerModel) {
        self.player = player
        self.radius = Float(Settings.Camera.gunRadius)
        self.mainColor = Colors.Container.mainColor
        self.missleRadius = 0
        
        var materials = [MaterialRenderData]()
        for (i, c) in player.ship.containers.enumerated() {
            for (j, m) in c.missles.enumerated() {
                let number = CGFloat(i) + CGFloat(j) / CGFloat(c.missles.count)
                let next = number + CGFloat(1) / CGFloat(c.missles.count)// - 0.01//CGFloat.leastNonzeroMagnitude
                var color = m.particles.first?.material.color ?? SIMD4<UInt8>(repeating: 0)//m.material.color
                color.w = 255;
                let material = MaterialRenderData(color: color, position: SIMD2(Float(number), Float(next)))
                materials.append(material)
            }
        }
        self.initialMaterials = materials
        createRenderData()
        updateRenderData()
    }
    
    func getWorldVisibleMissles(misslesFired: CGFloat) -> ClosedRange<CGFloat> {
        guard let containerIndex = player.ship.loadedContainerIndex,
              0..<player.ship.containers.count ~= containerIndex
        else { return 0...0 }
        
        let container = player.ship.containers[containerIndex]
        let missleWeight = CGFloat(1) / CGFloat(container.missles.count)
        
        let lo = CGFloat(containerIndex) + misslesFired * missleWeight
        let hi = CGFloat(Int(containerIndex)) + 1
        
        guard lo <= hi else { return 0...0 }
        
        return lo...hi
    }
    
    func getMissleRadius(levelToPackProgress: CGFloat, containerIndex: Int, missleIndexFloating: CGFloat) -> Float {
        let missleIndexFloating = missleIndexFloating - 1
        let missleIndex = max(0, Int(missleIndexFloating))
        let container = player.ship.containers[containerIndex]
        
        var currentRadius: CGFloat = 0
        var nextRadius: CGFloat = 0
        
        if 0..<container.missles.count ~= missleIndex {
            let currentMissle = container.missles[missleIndex]
            currentRadius = currentMissle.boundingRadius
        }
        
        if 0..<(container.missles.count - 1) ~= missleIndex {
            let nextMissle = container.missles[missleIndex + 1]
            nextRadius = nextMissle.boundingRadius
        }
        
        let scaleProgress = levelToPackProgress - Settings.Camera.levelCameraScale
        let mp = missleIndexFloating - CGFloat(missleIndex)
        
        let levelsMissleRadius: CGFloat = 0
        let levelMissleRadius: CGFloat = currentRadius + (nextRadius - currentRadius) * mp + Settings.Camera.gunMissleDeadZone
        let missleRadius = levelMissleRadius + (levelsMissleRadius - levelMissleRadius) * scaleProgress
        
        return Float(max(0, missleRadius))
    }
    
    func getRenderCenter(levelToPackProgress: CGFloat) -> SIMD2<Float> {
        let missleScale = 1 - max(0, min(1, levelToPackProgress - Settings.Camera.levelCameraScale))
        let renderCenterVerticalOffset = missleScale * (CGFloat(radius) + Settings.Camera.gunMissleCenterOffset)
        return SIMD2<Float32>(position.x, position.y - Float(renderCenterVerticalOffset))
    }
    
    func getMissleCenter() -> SIMD2<Float> {
        SIMD2<Float32>(position.x, position.y - radius - Float(Settings.Camera.gunMissleCenterOffset))
    }
    
    func updateAppearance(levelToPackProgress: CGFloat, visibleMissleRange: ClosedRange<CGFloat>) {
        let containerIndex = CGFloat(player.ship.loadedContainerIndex ?? 0)
        
        self.state.visibleMissleRange = visibleMissleRange
        self.state.currentContainerIndex = containerIndex
        
        let container = player.ship.containers[Int(containerIndex)]
        let missleIndex = CGFloat(container.missles.count) * (visibleMissleRange.lowerBound - CGFloat(Int(containerIndex)))
        self.missleRadius = getMissleRadius(levelToPackProgress: levelToPackProgress,
                                            containerIndex: Int(containerIndex),
                                            missleIndexFloating: missleIndex)
        
        self.renderCenter = getRenderCenter(levelToPackProgress: levelToPackProgress)
        self.missleCenter = getMissleCenter()
        
        let p = max(0, min(1, levelToPackProgress - Settings.Camera.levelsMenuCameraScale))
        let addScale = 1 + (visibleMissleRange.upperBound - visibleMissleRange.lowerBound - 1) * p // for packs menu
        let materialScale = min(max(1, Settings.Camera.packsMenuCameraScale - levelToPackProgress), Settings.Camera.gunMaterialsUpscaleInGame)
        
        let visibilityRange: Range<CGFloat> = CGFloat.leastNonzeroMagnitude..<materialScale
        let colorMixStrength: CGFloat = 1 - max(0, min(1, levelToPackProgress - Settings.Camera.levelCameraScale))
        
        var visibleCorrectedMaterials: [MaterialRenderData] = initialMaterials.enumerated().compactMap { _, m in
            let start = CGFloat(m.position.x)
            let end = CGFloat(m.position.y)
            
            let isInCurrentContainer = Int(start) == Int(containerIndex)
            let color = isInCurrentContainer ? m.color : m.color.mix(with: mainColor, progress: colorMixStrength)
            
            let convertedStart = (start - visibleMissleRange.lowerBound) * materialScale / addScale
            let convertedEnd = (end - visibleMissleRange.lowerBound) * materialScale / addScale
            
            if visibilityRange.contains(convertedStart) || visibilityRange.contains(convertedEnd) {
                return MaterialRenderData(color: color, position: SIMD2(Float(convertedStart), Float(convertedEnd)))
            }
            return nil
        }
        var rootColor = visibleCorrectedMaterials.first?.color ?? self.mainColor
        if levelToPackProgress == Settings.Camera.levelCameraScale {
            rootColor = mainColor
        }
        let rootPosition = SIMD2<Float>(Float(visibilityRange.lowerBound), Float(visibilityRange.upperBound))
        let rootMaterial = MaterialRenderData(color: rootColor, position: rootPosition)
        visibleCorrectedMaterials.append(rootMaterial)
        
        self.state.visibleMaterials = visibleCorrectedMaterials
        updateRenderData()
    }
    
    private func createRenderData() {
        let positionPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                               alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        let renderCenterPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                                   alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        let missleCenterPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                                   alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        let radiusPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float32>.stride,
                                                             alignment: MemoryLayout<Float32>.alignment)
        let missleRadiusPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float32>.stride,
                                                                   alignment: MemoryLayout<Float32>.alignment)
        self.renderData = .init(positionPointer: positionPointer,
                                renderCenterPointer: renderCenterPointer,
                                missleCenterPointer: missleCenterPointer,
                                radiusPointer: radiusPointer,
                                missleRadiusPointer: missleRadiusPointer,
                                materialsPointer: materialsPointer,
                                materialCount: materialCount)
    }
    
    private func updateRenderData() {
        guard let renderData = renderData else { return }
        
        renderData.positionPointer.copyMemory(from: &self.position, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        renderData.renderCenterPointer.copyMemory(from: &self.renderCenter, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        renderData.missleCenterPointer.copyMemory(from: &self.missleCenter, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        renderData.radiusPointer.copyMemory(from: &self.radius, byteCount: MemoryLayout<Float32>.stride)
        
        renderData.missleRadiusPointer.copyMemory(from: &self.missleRadius, byteCount: MemoryLayout<Float32>.stride)
        
        self.renderData?.materialsPointer = materialsPointer
        self.renderData?.materialCount = materialCount
    }
    
    private var materialCount: Int {
        state.visibleMaterials.count
    }
    
    private var materialsPointer: UnsafeMutableRawPointer {
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<MaterialRenderData>.stride * materialCount,
                                                       alignment: MemoryLayout<MaterialRenderData>.alignment)
        pointer.copyMemory(from: self.state.visibleMaterials, byteCount: MemoryLayout<MaterialRenderData>.stride * materialCount)
        return pointer
    }
}

extension GunBody: MissleHolder {
    func getMissleCenter() -> CGPoint {
        let starRadius = CGFloat(radius)
        
        let starCenter = CGPoint(x: CGFloat(position.x),
                                 y: CGFloat(position.y))
        return CGPoint(x: starCenter.x,
                       y: starCenter.y - starRadius - Settings.Camera.gunMissleCenterOffset)
    }
    
    func getInitialPositions(particleCount: Int) -> [SIMD2<Float32>] {
        let starRadius = CGFloat(radius)
        let missleRadius = CGFloat(missleRadius) + Settings.Camera.missleRadiusShiftInsideStar
        
        let starCenter = CGPoint(x: CGFloat(position.x),
                                 y: CGFloat(position.y))
        let missleCenter = CGPoint(x: starCenter.x,
                                   y: starCenter.y - starRadius - Settings.Camera.gunMissleCenterOffset)
        
        let d = missleCenter.distance(to: starCenter)
        
        // angle from missle center to star edge (intersection point)
        let intersectionAngle = CGFloat.circleIntersectionAngle(r1: missleRadius, r2: starRadius, d: d)
        let angleShift = missleCenter.angle(to: starCenter).radians
        
        // fill idle
        let idleAngleStart = intersectionAngle - Settings.Camera.missleAngleShiftInsideStar
        let idleAngleEnd = -intersectionAngle + Settings.Camera.missleAngleShiftInsideStar
        
        let angleStep = (idleAngleEnd - idleAngleStart) / CGFloat(particleCount - 1)
        
        return (0..<particleCount).map { i in
            let angle = angleShift + idleAngleStart + CGFloat(i) * angleStep
            
            let idleX = missleCenter.x + missleRadius * cos(angle)
            let idleY = missleCenter.y + missleRadius * sin(angle)
            
            return SIMD2<Float32>(x: Float32(idleX),
                                  y: Float32(idleY))
        }.shuffled()
    }
}
