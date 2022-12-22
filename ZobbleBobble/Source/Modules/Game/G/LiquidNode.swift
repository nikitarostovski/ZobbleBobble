//
//  LiquidNode.swift
//  ZobbleBobble
//
//  Created by Rost on 22.11.2022.
//

import Foundation
import CoreImage
import SpriteKit
import ZobblePhysics
import ZobbleCore
import simd

typealias Droplet = CGPoint

class LiquidNode: SKEffectNode {
    var particleRadius: CGFloat { world.particleRadius }
    var bodies: [ZPSoftBody] = []
    let world: World
    
    private let liquidFilter: LiquidFilter
    
    private var placeholder: SKShapeNode
    
    var droplets: [Droplet] {
        var droplets = [Droplet]()
        for body in bodies {
            for i in 0 ..< body.positions.count {
                let pos = body.positions[i].cgPointValue
                droplets.append(Droplet(x: pos.x, y: pos.y))
            }
        }
        return droplets
    }
    
    var lastSize: CGSize = .zero
    
    required init(world: World) {
        self.world = world
        self.liquidFilter = LiquidFilter()
        self.placeholder = SKShapeNode()
        
        super.init()
//        shouldRasterize = true
        
        
        placeholder.position = .zero
        placeholder.fillColor = .white
        placeholder.strokeColor = .white
        addChild(placeholder)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addLiquid(polygon: Polygon) {
        let polygon = polygon.map { NSValue(cgPoint: $0) }
        guard let body = ZPSoftBody(polygon: polygon, position: .zero, category: CAT_COMET, at: world.world) else { return }
        bodies.append(body)
        
        body.onContact = { (_: ZPBody?) -> Void in
            body.becomeDynamic()
        }
    }
    
    func addLiquid(radius: CGFloat, position: CGPoint) {
        let polygon = Polygon.make(radius: radius, position: position, vertexCount: 6)
        addLiquid(polygon: polygon)
    }
    
    func update() {
        let droplets = self.droplets
        guard !droplets.isEmpty else {
            self.filter = nil
            return
        }
        
        liquidFilter.droplets = droplets.map {
            let p = convert($0, from: world)

            let x = 2 * p.x + world.worldSize.width
            let y = world.worldSize.height - 2 * p.y
            return Droplet(x: x, y: y)
        }
        liquidFilter.radius = Float(particleRadius /*/ world.cameraScale*/)
        self.filter = liquidFilter
        
        let worldSize = world.worldSize
        guard lastSize != worldSize else {
            return
        }
        placeholder.path = CGPath(rect: CGRect(origin: CGPoint(x: -worldSize.width / 2, y: -worldSize.height / 2), size: worldSize), transform: nil)
        
        lastSize = worldSize
    }
}

class LiquidFilter: CIFilter {
    var droplets = [Droplet]()
    
    var radius: Float = 0
    
    static var lowResRenderKernel: CIColorKernel = { () -> CIColorKernel in
        let url = Bundle.main.url(forResource: "LiquidShaders", withExtension: "ci.metallib")!
        let data = try! Data(contentsOf: url)
        
        do {
            return try CIColorKernel(functionName: "render", fromMetalLibraryData: data)
        } catch {
            print("\(error)")
            fatalError("\(error)")
        }
    }()
    
    static var addKernel: CIKernel = { () -> CIKernel in
        let url = Bundle.main.url(forResource: "LiquidShaders", withExtension: "ci.metallib")!
        let data = try! Data(contentsOf: url)
        
        do {
            return try CIKernel(functionName: "addColor", fromMetalLibraryData: data)
        } catch {
            print("\(error)")
            fatalError("\(error)")
        }
    }()
    
    static var multiplyKernel: CIKernel = { () -> CIKernel in
        let url = Bundle.main.url(forResource: "LiquidShaders", withExtension: "ci.metallib")!
        let data = try! Data(contentsOf: url)
        
        do {
            return try CIKernel(functionName: "multiplyColor", fromMetalLibraryData: data)
        } catch {
            print("\(error)")
            fatalError("\(error)")
        }
    }()
    
    static var finalRenderKernel: CIKernel = { () -> CIKernel in
        let url = Bundle.main.url(forResource: "LiquidShaders", withExtension: "ci.metallib")!
        let data = try! Data(contentsOf: url)
        
        do {
            return try CIKernel(functionName: "renderFinal", fromMetalLibraryData: data)
        } catch {
            print("\(error)")
            fatalError("\(error)")
        }
    }()
    
    static var debugKernel: CIColorKernel = { () -> CIColorKernel in
        let url = Bundle.main.url(forResource: "LiquidShaders", withExtension: "ci.metallib")!
        let data = try! Data(contentsOf: url)
        
        do {
            return try CIColorKernel(functionName: "debugRender", fromMetalLibraryData: data)
        } catch {
            print("\(error)")
            fatalError("\(error)")
        }
    }()
    
    @objc dynamic var inputImage: CIImage?
    
    override var outputImage : CIImage? {
        guard let inputImage = self.inputImage, !droplets.isEmpty, inputImage.extent.width > 0 else { return nil }
        
        let lowResScale: Float = 0.2
        var lowResExtent = inputImage.extent
        lowResExtent.size.width *= CGFloat(lowResScale)
        lowResExtent.size.height *= CGFloat(lowResScale)


        var positionArray = droplets.map { SIMD2<Float>(Float($0.x) * lowResScale, Float($0.y) * lowResScale) }
        let pointer = UnsafeMutableRawPointer.allocate(
            byteCount: positionArray.count * MemoryLayout<SIMD2<Float>>.stride,
            alignment: MemoryLayout<SIMD2<Float>>.alignment)

        let sPointer = positionArray.withUnsafeMutableBufferPointer { (buffer) -> UnsafeMutablePointer<SIMD2<Float>> in
            let p = pointer.initializeMemory(as: SIMD2<Float>.self,
                                             from: buffer.baseAddress!,
                                             count: buffer.count)
            return p
        }
        let positionData = Data(bytesNoCopy: sPointer, count: positionArray.count * MemoryLayout<SIMD2<Float>>.stride, deallocator: .free)


        let arguments = [positionData, positionArray.count, radius * Float(lowResScale)] as [Any]
        var ciimage = Self.lowResRenderKernel.apply(extent: lowResExtent, arguments: arguments)



        let arguments2 = [ciimage as Any, lowResExtent.width, lowResExtent.height, inputImage.extent.width, inputImage.extent.height] as [Any]
        ciimage = Self.finalRenderKernel.apply(extent: inputImage.extent, roiCallback: { $1 }, arguments: arguments2)

        return ciimage
        
//        var positionArray: [SIMD2<Float>] = droplets.map { SIMD2<Float>(Float($0.x), Float($0.y)) }
//        let pointer = UnsafeMutableRawPointer.allocate(
//            byteCount: positionArray.count * MemoryLayout<SIMD2<Float>>.stride,
//            alignment: MemoryLayout<SIMD2<Float>>.alignment)
//
//        let sPointer = positionArray.withUnsafeMutableBufferPointer { (buffer) -> UnsafeMutablePointer<SIMD2<Float>> in
//            let p = pointer.initializeMemory(as: SIMD2<Float>.self,
//                                             from: buffer.baseAddress!,
//                                             count: buffer.count)
//            return p
//        }
//        let positionData = Data(bytesNoCopy: sPointer, count: positionArray.count * MemoryLayout<SIMD2<Float>>.stride, deallocator: .free)
//
//
//        let arguments = [positionData, positionArray.count, radius] as [Any]
//        return Self.debugKernel.apply(extent: inputImage.extent, arguments: arguments)
    }
}
