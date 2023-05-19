//
//  MetalRenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import UIKit
import MetalKit
import Levels

protocol RenderViewDelegate: AnyObject {
    func updateRenderData()
}

final class MetalRenderView: MTKView {
    var renderDelegate: RenderViewDelegate? {
        get { renderer?.renderDelegate }
        set { renderer?.renderDelegate = newValue }
    }
    var renderer: Renderer?
    
    var objectsDataSource: ObjectRenderDataSource? {
        get { renderer?.objectsDataSource }
        set { renderer?.objectsDataSource = newValue }
    }
    var cameraDataSource: CameraRenderDataSource? {
        get { renderer?.cameraDataSource }
        set { renderer?.cameraDataSource = newValue }
    }
    var backgroundDataSource: BackgroundRenderDataSource? {
        get { renderer?.backgroundDataSource }
        set { renderer?.backgroundDataSource = newValue }
    }
    var starsDataSource: StarsRenderDataSource? {
        get { renderer?.starsDataSource }
        set { renderer?.starsDataSource = newValue }
    }
    
    init(screenSize: CGSize, renderSize: CGSize) {
        let device = MTLCreateSystemDefaultDevice()!
        super.init(frame: .zero, device: device)
        
        self.renderer = Renderer(device: device, view: self, renderSize: renderSize, screenSize: screenSize)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Renderer: NSObject, MTKViewDelegate {
    weak var renderDelegate: RenderViewDelegate?
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var view: MTKView
    private var drawableRenderPipelineState: MTLRenderPipelineState!
    
    var uniqueMaterials: [MaterialType] = [] {
        didSet {
            resetTextures()
        }
    }
    
    private var textureCountBufferProvider: BufferProvider
    private var vertexBuffer: MTLBuffer?
    private var upscaleSamplerState: MTLSamplerState?
    private var vertexCount: Int = 0
    
    private let renderSize: CGSize
    private let screenSize: CGSize
    
    var starsMesh: StarsMesh?
    var liquidMesh: LiquidMesh?
    
    weak var objectsDataSource: ObjectRenderDataSource?
    weak var cameraDataSource: CameraRenderDataSource?
    weak var backgroundDataSource: BackgroundRenderDataSource?
    weak var starsDataSource: StarsRenderDataSource?
    
    init(device: MTLDevice, view: MTKView, renderSize: CGSize, screenSize: CGSize) {
        self.screenSize = screenSize
        self.renderSize = renderSize
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        self.textureCountBufferProvider = BufferProvider(device: device,
                                                         inflightBuffersCount: Settings.inflightBufferCount,
                                                         bufferSize: MemoryLayout<Int>.stride)
        super.init()
        view.device = device
        view.delegate = self

        self.starsMesh = StarsMesh(device, screenSize: screenSize, renderSize: renderSize)
        self.liquidMesh = LiquidMesh(device, screenSize: screenSize, renderSize: renderSize)
        
        resetTextures()
        makePipeline()
    }
    
    private func resetTextures() {
        liquidMesh?.uniqueMaterials = uniqueMaterials
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
        
        let s = MTLSamplerDescriptor()
        s.magFilter = .nearest
        s.minFilter = .nearest
        self.upscaleSamplerState = device.makeSamplerState(descriptor: s)
    }
    
    func draw(in view: MTKView) {
        renderDelegate?.updateRenderData()
        self.view = view
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let objectsDataSource = objectsDataSource,
              let cameraDataSource = cameraDataSource,
              let starsDataSource = starsDataSource else {
            return
        }
        
        let camera = SIMD2<Float32>(cameraDataSource.cameraX, cameraDataSource.cameraY)
        let cameraScale = cameraDataSource.cameraScale
        
        let liquidTextures = liquidMesh?.render(commandBuffer: commandBuffer,
                                                vertexCount: objectsDataSource.liquidCount,
                                                staticVertexCount: objectsDataSource.staticLiquidCount,
                                                fadeMultiplier: objectsDataSource.liquidFadeModifier,
                                                vertices: objectsDataSource.liquidPositions,
                                                staticVertices: objectsDataSource.staticLiquidPositions,
                                                velocities: objectsDataSource.liquidVelocities,
                                                staticVelocities: objectsDataSource.staticLiquidVelocities,
                                                colors: objectsDataSource.liquidColors,
                                                staticColors: objectsDataSource.staticLiquidColors,
                                                particleRadius: objectsDataSource.particleRadius,
                                                cameraScale: cameraScale,
                                                camera: camera) ?? []
        
//        let starTexture = liquidMesh?.getClearTexture(commandBuffer: commandBuffer)
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
        
        let allTextures = [starTexture].compactMap { $0 } + liquidTextures
        var textureCount = allTextures.count
        
        _ = textureCountBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let textureCountBuffer = textureCountBufferProvider.nextUniformsBuffer(data: &textureCount, length: MemoryLayout<Int>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.textureCountBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        guard !allTextures.isEmpty,
              let vertexBuffer = vertexBuffer,
              let upscaleSamplerState = upscaleSamplerState,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }
        
        renderEncoder.setRenderPipelineState(drawableRenderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder.setFragmentTextures(allTextures, range: 0..<textureCount)
        renderEncoder.setFragmentBuffer(textureCountBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(upscaleSamplerState, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
