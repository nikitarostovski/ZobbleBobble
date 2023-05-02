//
//  MetalRenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import UIKit
import MetalKit

final class MetalRenderView: MTKView {
    var renderer: Renderer!
    
    var starsMesh: StarsMesh? {
        get { renderer.starsMesh }
        set { renderer.starsMesh = newValue }
    }
    var liquidMesh: LiquidMesh? {
        get { renderer.liquidMesh }
        set { renderer.liquidMesh = newValue }
    }
    var missleMesh: LiquidMesh? {
        get { renderer.missleMesh }
        set { renderer.missleMesh = newValue }
    }
    
    var objectsDataSource: ObjectRenderDataSource? {
        get { renderer.objectsDataSource }
        set { renderer.objectsDataSource = newValue }
    }
    var cameraDataSource: CameraRenderDataSource? {
        get { renderer.cameraDataSource }
        set { renderer.cameraDataSource = newValue }
    }
    var backgroundDataSource: BackgroundRenderDataSource? {
        get { renderer.backgroundDataSource }
        set { renderer.backgroundDataSource = newValue }
    }
    var starsDataSource: StarsRenderDataSource? {
        get { renderer.starsDataSource }
        set { renderer.starsDataSource = newValue }
    }
    
    init(screenSize: CGSize, renderSize: CGSize) {
        let device = MTLCreateSystemDefaultDevice()!
        super.init(frame: .zero, device: device)
        self.renderer = Renderer(device: device, view: self, renderSize: renderSize)
        
        self.liquidMesh = LiquidMesh(device, screenSize: screenSize, renderSize: renderSize)
        self.missleMesh = LiquidMesh(device, screenSize: screenSize, renderSize: renderSize)
        self.starsMesh = StarsMesh(device, screenSize: screenSize, renderSize: renderSize)
        
        self.delegate = renderer
        
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    private let renderSize: CGSize
    
    var starsMesh: StarsMesh?
    var liquidMesh: LiquidMesh?
    var missleMesh: LiquidMesh?
    
    weak var objectsDataSource: ObjectRenderDataSource?
    weak var cameraDataSource: CameraRenderDataSource?
    weak var backgroundDataSource: BackgroundRenderDataSource?
    weak var starsDataSource: StarsRenderDataSource?
    
    init(device: MTLDevice, view: MTKView, renderSize: CGSize) {
        self.renderSize = renderSize
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        super.init()
        view.device = device
        view.delegate = self
        makePipeline()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {
            return
        }
        let drawableRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        drawableRenderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_render")!
        drawableRenderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_render")!
        drawableRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
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
        
        var size: SIMD2<Float> = SIMD2<Float>(Float(renderSize.width), Float(renderSize.height))
        self.screenSizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<SIMD2<Float>>.stride)
        
        let s = MTLSamplerDescriptor()
//        s.magFilter = .linear
        self.upscaleSamplerState = device.makeSamplerState(descriptor: s)
    }
    
    func draw(in view: MTKView) {
        self.view = view
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let vertexBuffer = vertexBuffer,
              let upscaleSamplerState = upscaleSamplerState,
              let objectsDataSource = objectsDataSource,
              let cameraDataSource = cameraDataSource,
              let starsDataSource = starsDataSource
        else {
            return
        }
        
        let camera = SIMD2<Float32>(cameraDataSource.cameraX, cameraDataSource.cameraY)
        let cameraScale = cameraDataSource.cameraScale
        let coreAngle = cameraDataSource.cameraAngle
        
        let liquidTexture = liquidMesh?.render(commandBuffer: commandBuffer,
                                               vertexCount: objectsDataSource.liquidCount,
                                               fadeMultiplier: objectsDataSource.liquidFadeModifier,
                                               vertices: objectsDataSource.liquidPositions,
                                               velocities: objectsDataSource.liquidVelocities,
                                               colors: objectsDataSource.liquidColors,
                                               particleRadius: objectsDataSource.particleRadius,
                                               cameraAngle: coreAngle,
                                               cameraScale: cameraScale,
                                               camera: camera)
        
        let missleTexture = missleMesh?.render(commandBuffer: commandBuffer,
                                               vertexCount: objectsDataSource.staticLiquidCount,
                                               fadeMultiplier: 0,
                                               vertices: objectsDataSource.staticLiquidPositions,
                                               velocities: objectsDataSource.staticLiquidVelocities,
                                               colors: objectsDataSource.staticLiquidColors,
                                               particleRadius: objectsDataSource.particleRadius,
                                               cameraAngle: 0,
                                               cameraScale: cameraScale,
                                               camera: camera)
        
        let starTexture = starsMesh?.render(commandBuffer: commandBuffer,
                                            position: starsDataSource.starPositions.first,
                                            renderCenter: starsDataSource.starRenderCenters.first,
                                            missleCenter: starsDataSource.starMissleCenters.first,
                                            radius: starsDataSource.starRadii.first,
                                            missleRadius: starsDataSource.starMissleRadii.first,
                                            materials: starsDataSource.starMaterials.first,
                                            materialCount: starsDataSource.starMaterialCounts.first ?? 0,
                                            hasChanges: starsDataSource.starsHasChanges,
                                            cameraScale: cameraScale,
                                            camera: camera)
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }
        
        renderEncoder.setRenderPipelineState(drawableRenderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder.setFragmentTexture(liquidTexture, index: 0)
        renderEncoder.setFragmentTexture(missleTexture, index: 1)
        renderEncoder.setFragmentTexture(starTexture, index: 2)
        renderEncoder.setFragmentBuffer(screenSizeBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(upscaleSamplerState, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
