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

extension Array where Element == Droplet {
    mutating func makePositionData() -> (Data, Int) {
        let pointer = UnsafeMutableRawPointer.allocate(
            byteCount: count * MemoryLayout<CGPoint>.stride,
            alignment: MemoryLayout<CGPoint>.alignment)
        
        var d = self
        let sPointer = d.withUnsafeMutableBufferPointer { (buffer) -> UnsafeMutablePointer<CGPoint> in
            let p = pointer.initializeMemory(as: CGPoint.self,
                                             from: buffer.baseAddress!,
                                             count: buffer.count)
            return p
        }
        let data = Data(bytesNoCopy: sPointer, count: count * MemoryLayout<CGPoint>.stride, deallocator: .free)
        return (data, d.count)
    }
}

class LiquidNode: SKEffectNode {
    var particleRadius: CGFloat = 0
    var body: ZPSoftBody?
    let world: World
    
    var boundingBox: CGRect {
        guard let body = body else { return .zero }
        
        var left: CGFloat = .greatestFiniteMagnitude
        var top: CGFloat = .greatestFiniteMagnitude
        var right: CGFloat = .greatestFiniteMagnitude * -1
        var bottom: CGFloat = .greatestFiniteMagnitude * -1
        
        for i in 0 ..< body.positions.count {
            let pos = body.positions[i].cgPointValue
            
            left = min(left, CGFloat(pos.x) - particleRadius)
            top = min(top, CGFloat(pos.y) - particleRadius)
            right = max(right, CGFloat(pos.x) + particleRadius)
            bottom = max(bottom, CGFloat(pos.y) + particleRadius)
        }
        
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }
    
    private let liquidFilter: LiquidFilter
    
    private var placeholder: SKShapeNode
    
    var droplets: [Droplet] {
        guard let body = body else { return [] }
        
        var droplets = [Droplet]()
        for i in 0 ..< body.positions.count {
            let pos = body.positions[i].cgPointValue
            droplets.append(Droplet(x: pos.x, y: pos.y))
        }
        return droplets
    }
    
    init(world: World, body: Polygon, color: UIColor, particleRadius: CGFloat) {
        self.world = world
        self.particleRadius = particleRadius
        self.liquidFilter = LiquidFilter()
        self.placeholder = SKShapeNode()
        
        super.init()
        shouldRasterize = true
        
        
        placeholder.position = .zero
        placeholder.fillColor = .white
        placeholder.strokeColor = .white
        addChild(placeholder)
        
        let polygon = body.map { NSValue(cgPoint: $0) }
        self.body = ZPSoftBody(polygon: polygon, position: .zero, color: Self.uiColorToCGRect(color), at: world.world)
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update(displayLink:)))
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: .current, forMode: .default)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var lastSize: CGSize = .zero
    
    
    @objc
    func update(displayLink: CADisplayLink) {
        let droplets = self.droplets
        guard !droplets.isEmpty else {
            self.filter = nil
            return
        }
        
        liquidFilter.currentDroplets = droplets.map {
            let p = convert($0, from: world)

            let x = 2 * p.x + world.worldSize.width
            let y = world.worldSize.height - 2 * p.y
            return Droplet(x: x, y: y)
        }
        liquidFilter.radius = Float(4 * particleRadius / world.cameraScale)
        self.filter = liquidFilter
        
        let worldSize = world.worldSize
        guard lastSize != worldSize else {
            return
        }
        placeholder.path = CGPath(rect: CGRect(origin: CGPoint(x: -worldSize.width / 2, y: -worldSize.height / 2), size: worldSize), transform: nil)
        
        lastSize = worldSize
    }
    
    private static func uiColorToCGRect(_ color: UIColor) -> CGRect {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return CGRect(x: r * 255, y: g * 255, width: b * 255, height: 0)
    }
}

class LiquidFilter: CIFilter {
    var lastDroplets = [Droplet]()
    var currentDroplets = [Droplet]()
    
    var droplets: [Droplet] {
        currentDroplets + lastDroplets
    }
    
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
        
//        let lowResScale: Float = 1//0.075
//        var lowResExtent = inputImage.extent
//        lowResExtent.size.width *= CGFloat(lowResScale)
//        lowResExtent.size.height *= CGFloat(lowResScale)
//
//
//        var positionArray = droplets.map { SIMD2<Float>(Float($0.x) * lowResScale, Float($0.y) * lowResScale) }
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
//        let arguments = [positionData, positionArray.count, radius * Float(lowResScale)] as [Any]
//        var ciimage = Self.lowResRenderKernel.apply(extent: lowResExtent, arguments: arguments)
//
//
//
//        let arguments2 = [ciimage as Any, lowResExtent.width, lowResExtent.height, inputImage.extent.width, inputImage.extent.height] as [Any]
//        ciimage = Self.finalRenderKernel.apply(extent: inputImage.extent, roiCallback: { $1 }, arguments: arguments2)
//
//        return ciimage
        
        var positionArray = droplets.map { SIMD2<Float>(Float($0.x), Float($0.y)) }
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
        
        
        let arguments = [positionData, positionArray.count, radius] as [Any]
        return Self.debugKernel.apply(extent: inputImage.extent, arguments: arguments)
    }
}
