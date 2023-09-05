//
//  Renderer.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation
import MetalKit
import MetalPerformanceShaders

protocol RenderDataSource: AnyObject {
    var visibleScenes: [Scene] { get }
}

protocol RenderDelegate: AnyObject {
    func rendererSizeDidChange(size: CGSize)
    func updateRenderData(time: TimeInterval)
}

struct ShaderOptions: Codable {
    var bloom: Int32
    var bloomRadiusR: Float
    var bloomRadiusG: Float
    var bloomRadiusB: Float
    var bloomBrightness: Float
    var bloomWeight: Float
    
    var dotMask: Int32
    var dotMaskBrightness: Float
    
    var scanlines: Int32
    var scanlineBrightness: Float
    var scanlineWeight: Float
    
    var disalignment: Int32
    var disalignmentH: Float
    var disalignmentV: Float
}

class Renderer: NSObject, MTKViewDelegate {
    struct FragmentUniforms {
        var alpha: Float
        var white: Float
        var dotMaskWidth: Int32
        var dotMaskHeight: Int32
        var scanlineDistance: Int32
    }
    
    weak var delegate: RenderDelegate?
    weak var dataSource: RenderDataSource?
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    private var drawableRenderPipelineState: MTLRenderPipelineState!
    private var mergePipelineState: MTLComputePipelineState!
    private var channelSplitPipelineState: MTLComputePipelineState!
    
    private var textureCountBufferProvider: BufferProvider
    private var backgroundColorBufferProvider: BufferProvider
    private var optionsBuffer: MTLBuffer?
    private var fragUniformsBuffer: MTLBuffer?
    private var blendModeBuffer: MTLBuffer?
    private var vertexBuffer: MTLBuffer?
    private var upscaleSamplerState: MTLSamplerState?
    
    private var finalTexture: MTLTexture?
    
    private var bloomTextureR: MTLTexture!
    private var bloomTextureG: MTLTexture!
    private var bloomTextureB: MTLTexture!
    private var dotMaskTexture: MTLTexture!
    
    private var vertexCount: Int = 0
    
    /// Blending mode for texture merge shader. Look at `blend` shader method for details
    private var blendMode: Int32 = 1
    
    private var renderSize: CGSize = .zero
    private var gameTextureSize: CGSize = .zero
    
    private var lastDrawDate: Date?
    private var sceneRenderers = [SceneRenderer]()
    
    private var shaderOptions = ShaderOptions(bloom: Settings.Graphics.postprocessingEnabled ? 1 : 0, // 1
                                              bloomRadiusR: 1.0, // 1.0
                                              bloomRadiusG: 1.0, // 1.0
                                              bloomRadiusB: 1.0, // 1.0
                                              bloomBrightness: 0.4, // 0.4
                                              bloomWeight: 1.21, // 1.21
                                              dotMask: Settings.Graphics.postprocessingEnabled ? 1 : 0, // 1
                                              dotMaskBrightness: 0.7, // 0.7
                                              scanlines: Settings.Graphics.postprocessingEnabled ? 2 : 0, // 2
                                              scanlineBrightness: 0.55, // 0.55
                                              scanlineWeight: 0.11, // 0.11
                                              disalignment: 0, // 1
                                              disalignmentH: 0.002, // 0.002
                                              disalignmentV: 0.002) // 0.002
    private var uniforms = FragmentUniforms(alpha: 1,
                                            white: 0,
                                            dotMaskWidth: 0,
                                            dotMaskHeight: 0,
                                            scanlineDistance: 6)
    
    init(view: MTKView, delegate: RenderDelegate?, dataSource: RenderDataSource?, renderSize: CGSize) {
        self.device = view.device!
        self.delegate = delegate
        self.dataSource = dataSource
        self.commandQueue = device.makeCommandQueue()!
        
        self.textureCountBufferProvider = BufferProvider(device: device,
                                                         inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                         bufferSize: MemoryLayout<Int>.stride)
        
        self.backgroundColorBufferProvider = BufferProvider(device: device,
                                                            inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                            bufferSize: MemoryLayout<SIMD4<UInt8>>.stride)
        super.init()
        view.delegate = self
        
        setupPipeline()
        onSizeUpdate(renderSize)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        delegate?.rendererSizeDidChange(size: size)
    }
    
    func draw(in view: MTKView) {
        view.isPaused = true
        defer { view.isPaused = false }
        
        var time: TimeInterval = 0
        let now = Date()
        if let lastDrawDate = lastDrawDate {
            time = now.timeIntervalSince(lastDrawDate)
        }
        lastDrawDate = now
        
        delegate?.updateRenderData(time: time)
        updateSceneRenderersIfNeeded()
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        defer { commandBuffer.commit() }
        
        let sceneTextures = sceneRenderers.map { $0.render(commandBuffer) }
        var sceneCount = sceneTextures.count
        
        guard sceneCount > 0 else { return }
        
        _ = textureCountBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let textureCountBuffer = textureCountBufferProvider.nextUniformsBuffer(data: &sceneCount, length: MemoryLayout<Int>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.textureCountBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        guard let finalTexture = finalTexture,
              let mergePipelineState = mergePipelineState,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else { return }
        
        computeEncoder.setComputePipelineState(mergePipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTextures(sceneTextures, range: 1..<(sceneCount + 1))
        computeEncoder.setBuffer(textureCountBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(blendModeBuffer, offset: 0, index: 1)
        computeEncoder.setSamplerState(upscaleSamplerState, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: mergePipelineState, width: finalTexture.width, height: finalTexture.height)
        
        if shaderOptions.bloom != 0 {
            func applyGauss(_ texture: inout MTLTexture, radius: Float) {
                let gauss = MPSImageGaussianBlur(device: device, sigma: radius)
                gauss.encode(commandBuffer: commandBuffer, inPlaceTexture: &texture, fallbackCopyAllocator: nil)
            }
            
            computeEncoder.setComputePipelineState(channelSplitPipelineState)
            computeEncoder.setTexture(finalTexture, index: 0)
            computeEncoder.setTexture(bloomTextureR, index: 1)
            computeEncoder.setTexture(bloomTextureG, index: 2)
            computeEncoder.setTexture(bloomTextureB, index: 3)
            computeEncoder.setBuffer(optionsBuffer, offset: 0, index: 0)
            ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: channelSplitPipelineState, width: finalTexture.width, height: finalTexture.height)
            computeEncoder.endEncoding()
            
            applyGauss(&bloomTextureR, radius: shaderOptions.bloomRadiusR)
            applyGauss(&bloomTextureG, radius: shaderOptions.bloomRadiusG)
            applyGauss(&bloomTextureB, radius: shaderOptions.bloomRadiusB)
        } else {
            computeEncoder.endEncoding()
        }
        
        guard let vertexBuffer = vertexBuffer,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }
        
        renderEncoder.setRenderPipelineState(drawableRenderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(finalTexture, index: 0)
        renderEncoder.setFragmentTexture(bloomTextureR, index: 1)
        renderEncoder.setFragmentTexture(bloomTextureG, index: 2)
        renderEncoder.setFragmentTexture(bloomTextureB, index: 3)
        renderEncoder.setFragmentTexture(dotMaskTexture, index: 4)
        renderEncoder.setFragmentBuffer(optionsBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(fragUniformsBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentSamplerState(upscaleSamplerState, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
    }
    
    private func setupPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            return
        }
        let drawableRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        drawableRenderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_render")!
        drawableRenderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_render")!
        drawableRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
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
        
        upscaleSamplerState = device.nearestSampler
        
        do {
            mergePipelineState = try device.makeComputePipelineState(function: library.makeFunction(name: "merge")!)
            channelSplitPipelineState = try device.makeComputePipelineState(function: library.makeFunction(name: "split")!)
        } catch {
            print(error)
        }
        self.optionsBuffer = device.makeBuffer(bytes: &shaderOptions, length: MemoryLayout<ShaderOptions>.stride)
        self.blendModeBuffer = device.makeBuffer(bytes: &blendMode, length: MemoryLayout<Int32>.stride)
    }
    
    private func updateSceneRenderersIfNeeded() {
        guard let visibleScenes = dataSource?.visibleScenes else { return }
        
        var newRenderers = sceneRenderers
        
        // Add new
        for scene in visibleScenes {
            var found = false
            for renderer in newRenderers {
                if renderer.scene === scene {
                    found = true
                    break
                }
            }
            if !found {
                let renderer = SceneRenderer(scene: scene, device: device, renderSize: renderSize, gameTextureSize: gameTextureSize)
                newRenderers.append(renderer)
            }
        }
        
        // Remove old
        newRenderers = newRenderers.filter { renderer in
            visibleScenes.first(where: { renderer.scene === $0 }) != nil
        }
        
        sceneRenderers = newRenderers
    }
    
    private func onSizeUpdate(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        
        // Recalc sizes
        renderSize = CGSize(width: size.width,
                            height: size.height)
        gameTextureSize = CGSize(width: size.width * Settings.Camera.sceneHeight / size.height,
                                 height: Settings.Camera.sceneHeight)
        
        // Regenerate textures and buffers
        finalTexture = device.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height), usage: [.shaderRead, .shaderWrite, .renderTarget])
        
        bloomTextureR = device.makeTexture(width: Int(size.width), height: Int(size.height))
        bloomTextureG = device.makeTexture(width: Int(size.width), height: Int(size.height))
        bloomTextureB = device.makeTexture(width: Int(size.width), height: Int(size.height))
        
        if let dotMaskImage = DotMask.makeDotMask(Settings.Graphics.dotMaskType, brightness: shaderOptions.dotMaskBrightness) {
            dotMaskTexture = dotMaskImage.toTexture(device: device)
            uniforms.dotMaskWidth = Int32(dotMaskTexture.width)
            uniforms.dotMaskHeight = Int32(dotMaskTexture.height)
        }
        fragUniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<FragmentUniforms>.stride)
        
        // Reset scene renderers
        updateSceneRenderersIfNeeded()
    }
}
