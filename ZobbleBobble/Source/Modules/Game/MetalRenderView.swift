//
//  MetalRenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import UIKit
import MetalKit

final class MetalRenderView: MTKView {
    let scale: CGFloat = 1
    var renderer: Renderer!
    
    var backgroundMesh: BackgroundMesh
    var polygonMesh: PolygonMesh
    var circleMesh: CircleMesh
    var liquidMesh: LiquidMesh
    
    weak var dataSource: RenderDataSource?
    
    init() {
        let device = MTLCreateSystemDefaultDevice()!
        
        let size = CGSize(width: UIScreen.main.bounds.width / scale, height: UIScreen.main.bounds.height / scale)
        
        self.backgroundMesh = BackgroundMesh(device, size: size)
        self.polygonMesh = PolygonMesh(device)
        self.circleMesh = CircleMesh(device, size: size)
        self.liquidMesh = LiquidMesh(device, size: size)
        super.init(frame: .zero, device: device)
        self.renderer = Renderer(device: device, view: self)
        self.delegate = renderer
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        guard let dataSource = dataSource else { return }
        
        let camera = SIMD2<Float32>(dataSource.cameraX, dataSource.cameraY)
        let cameraScale = dataSource.cameraScale
        let coreAngle = dataSource.cameraAngle
        
//        print("circles: \(dataSource.circleBodyCount) liquids: \(dataSource.liquidCount)")
        
        liquidMesh.updateMeshIfNeeded(vertexCount: dataSource.liquidCount, fadeMultiplier: dataSource.liquidFadeModifier, vertices: dataSource.liquidPositions, velocities: dataSource.liquidVelocities, colors: dataSource.liquidColors, particleRadius: dataSource.particleRadius, cameraAngle: coreAngle, cameraScale: cameraScale, camera: camera)
        circleMesh.updateMeshIfNeeded(positions: dataSource.circleBodiesPositions, radii: dataSource.circleBodiesRadii, colors: dataSource.circleBodiesColors, count: dataSource.circleBodyCount, cameraScale: cameraScale, camera: camera)
        
//        if let backgroundAnchorPointCount = dataSource.backgroundAnchorPointCount, let backgroundAnchorPositions = dataSource.backgroundAnchorPositions, let backgroundAnchorRadii = dataSource.backgroundAnchorRadii, let backgroundAnchorColors = dataSource.backgroundAnchorColors {
//            self.backgroundMesh.updateMeshIfNeeded(positions: backgroundAnchorPositions, radii: backgroundAnchorRadii, colors: backgroundAnchorColors, count: backgroundAnchorPointCount, cameraScale: cameraScale, camera: camera)
//        }
        renderer.setRenderData(backgroundMesh: backgroundMesh, polygonMesh: polygonMesh, circleMesh: circleMesh, liquidMesh: liquidMesh)
    }
}

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var view: MTKView
    private var drawableRenderPipelineState: MTLRenderPipelineState!
    
    private var screenSizeBuffer: MTLBuffer?
    private var vertexBuffer: MTLBuffer?
    private var upscaleSamplerState: MTLSamplerState?
    private var vertexCount: Int = 0
    
    var backgroundMesh: BackgroundMesh?
    var polygonMesh: PolygonMesh?
    var circleMesh: CircleMesh?
    var liquidMesh: LiquidMesh?
    
    init(device: MTLDevice, view: MTKView) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        super.init()
        view.device = device
        view.delegate = self
        makePipeline()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func setRenderData(backgroundMesh: BackgroundMesh?, polygonMesh: PolygonMesh?, circleMesh: CircleMesh?, liquidMesh: LiquidMesh?) {
        self.backgroundMesh = backgroundMesh
        self.polygonMesh = polygonMesh
        self.circleMesh = circleMesh
        self.liquidMesh = liquidMesh
    }
    
    func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {
            return
        }
        let drawableRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        drawableRenderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_render")!
        drawableRenderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_render")!
        drawableRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        drawableRenderPipelineDescriptor.sampleCount = 1;
        do {
            drawableRenderPipelineState = try device.makeRenderPipelineState(descriptor: drawableRenderPipelineDescriptor)
        } catch {
            print(error)
            return
        }
        let vertices: [SIMD4<Float>] = [
            SIMD4<Float>( 1, -1, 1.0, 1.0),
            SIMD4<Float>(-1, -1, 0.0, 1.0),
            SIMD4<Float>(-1,  1, 0.0, 0.0),
            SIMD4<Float>( 1, -1, 1.0, 1.0),
            SIMD4<Float>(-1,  1, 0.0, 0.0),
            SIMD4<Float>( 1,  1, 1.0, 0.0)
        ]
        
        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SIMD4<Float>>.stride * vertices.count,
            options: .storageModeShared)!
        vertexCount = vertices.count
        
        var size: SIMD2<Float> = SIMD2<Float>(Float(UIScreen.main.bounds.size.width), Float(UIScreen.main.bounds.size.height))
        self.screenSizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<SIMD2<Float>>.stride)
        
        let s = MTLSamplerDescriptor()
//        s.magFilter = .linear
        self.upscaleSamplerState = device.makeSamplerState(descriptor: s)
    }
    
    func draw(in view: MTKView) {
        self.view = view
        guard let drawableRenderPassDescriptor = view.currentRenderPassDescriptor else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let vertexBuffer = vertexBuffer, let upscaleSamplerState = upscaleSamplerState else { return }
        
        let backgroundTexture = backgroundMesh?.render(commandBuffer: commandBuffer)
        let liquidTexture = liquidMesh?.render(commandBuffer: commandBuffer)
        let circlesTexture = circleMesh?.render(commandBuffer: commandBuffer)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: drawableRenderPassDescriptor) else { return }
        renderEncoder.setRenderPipelineState(drawableRenderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(backgroundTexture, index: 0)
        renderEncoder.setFragmentTexture(liquidTexture, index: 1)
        renderEncoder.setFragmentTexture(circlesTexture, index: 2)
        renderEncoder.setFragmentBuffer(screenSizeBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(upscaleSamplerState, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
