//
//  Renderer.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation
import MetalKit
import MetalPerformanceShaders
import Levels

struct FragmentUniforms {
    var alpha: Float
    var white: Float
    var dotMaskWidth: Int32
    var dotMaskHeight: Int32
    var scanlineDistance: Int32
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
    weak var renderDelegate: RenderViewDelegate?
    weak var renderDataSource: RenderViewDataSource?
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    private let computePassDescriptor = MTLComputePassDescriptor()
    
    private var drawableRenderPipelineState: MTLRenderPipelineState!
    private var mergePipelineState: MTLComputePipelineState!
    private var upscalePipelineState: MTLComputePipelineState!
    private var channelSplitPipelineState: MTLComputePipelineState!
    private var scanlinesPipelineState: MTLComputePipelineState!
    
    private var textureCountBufferProvider: BufferProvider
    private var optionsBuffer: MTLBuffer?
    private var fragUniformsBuffer: MTLBuffer?
    private var vertexBuffer: MTLBuffer?
    private var upscaleSamplerState: MTLSamplerState?
    
    private var finalTexture: MTLTexture?
    private var mergeTexture: MTLTexture?
    
    private var bloomTextureR: MTLTexture!
    private var bloomTextureG: MTLTexture!
    private var bloomTextureB: MTLTexture!
    private var dotMaskTexture: MTLTexture!
    
    private var vertexCount: Int = 0
    
    private var renderSize: CGSize
    private let screenSize: CGSize
    
    private var lastDrawDate: Date?
    
    private var starNodes = [StarNode]()
    private var liquidNodes = [LiquidNode]()
    
    private var allNodes: [Node] {
        starNodes + liquidNodes
    }
    
    // TODO: move to settings
    private var shaderOptions = ShaderOptions(bloom: 1, // 1
                                              bloomRadiusR: 4.0, // 1.0
                                              bloomRadiusG: 4.0, // 1.0
                                              bloomRadiusB: 4.0, // 1.0
                                              bloomBrightness: 0.6, // 0.4
                                              bloomWeight: 1.21, // 1.21
                                              dotMask: 1, // 1
                                              dotMaskBrightness: 0.7, // 0.7
                                              scanlines: 1, // 2
                                              scanlineBrightness: 0.15, // 0.55
                                              scanlineWeight: 0.07, // 0.11
                                              disalignment: 0, // 1
                                              disalignmentH: 0.002, // 0.002
                                              disalignmentV: 0.002) // 0.002
    private var uniforms = FragmentUniforms(alpha: 1,
                                            white: 0,
                                            dotMaskWidth: 0,
                                            dotMaskHeight: 0,
                                            scanlineDistance: 6)
    
    init(device: MTLDevice, view: MTKView, screenSize: CGSize, delegate: RenderViewDelegate?, dataSource: RenderViewDataSource?) {
        self.screenSize = screenSize
        self.renderSize = CGSize(width: screenSize.width / Settings.Graphics.resolutionDownscale,
                                 height: screenSize.height / Settings.Graphics.resolutionDownscale)
        self.device = device
        self.renderDelegate = delegate
        self.renderDataSource = dataSource
        self.commandQueue = device.makeCommandQueue()!
        
        self.textureCountBufferProvider = BufferProvider(device: device,
                                                         inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                         bufferSize: MemoryLayout<Int>.stride)
        super.init()
        view.device = device
        view.delegate = self
        
        setupPipeline()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.renderSize = CGSize(width: screenSize.width / Settings.Graphics.resolutionDownscale,
                                 height: screenSize.height / Settings.Graphics.resolutionDownscale)
        
        
        self.mergeTexture = device.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))
        self.finalTexture = device.makeTexture(width: Int(size.width), height: Int(size.height), usage: [.shaderRead, .shaderWrite, .renderTarget])
        
        self.bloomTextureR = device.makeTexture(width: Int(size.width), height: Int(size.height))
        self.bloomTextureG = device.makeTexture(width: Int(size.width), height: Int(size.height))
        self.bloomTextureB = device.makeTexture(width: Int(size.width), height: Int(size.height))
        
        if let dotMaskImage = DotMask.makeDotMask(Settings.Graphics.dotMaskType, brightness: shaderOptions.dotMaskBrightness) {
            self.dotMaskTexture = dotMaskImage.toTexture(device: device)
            uniforms.dotMaskWidth = Int32(dotMaskTexture.width)
            uniforms.dotMaskHeight = Int32(dotMaskTexture.height)
        }
        self.fragUniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<FragmentUniforms>.stride)
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
        
        self.upscaleSamplerState = device.nearestSampler
        
        self.mergePipelineState = try? device.makeComputePipelineState(function: library.makeFunction(name: "merge")!)
        self.upscalePipelineState = try? device.makeComputePipelineState(function: library.makeFunction(name: "upscale_texture")!)
        self.channelSplitPipelineState = try? device.makeComputePipelineState(function: library.makeFunction(name: "split")!)
        
        self.optionsBuffer = device.makeBuffer(bytes: &shaderOptions, length: MemoryLayout<ShaderOptions>.stride)
    }
    
    private func updateNodesIfNeeded() {
        guard let bodies = renderDataSource?.visibleBodies else { return }
        let nodes = allNodes
        
        for body in bodies {
            var found = false
            for node in nodes {
                if node.linkedBody === body {
                    found = true
                    break
                }
            }
            if !found {
                addNode(for: body)
            }
        }
        
        for node in nodes {
            var found = false
            for body in bodies {
                if body === node.linkedBody {
                    found = true
                    break
                }
            }
            if !found {
                starNodes.removeAll(where: { $0 === node })
                liquidNodes.removeAll(where: { $0 === node })
            }
        }
    }
    
    private func addNode(for body: any Body) {
        switch body {
        case is StarBody:
            let node = StarNode(device, screenSize: screenSize, renderSize: renderSize, body: body as? StarBody)
            starNodes.append(node)
        case is LiquidBody:
            for material in body.uniqueMaterials {
                if let node = LiquidNode(device, screenSize: screenSize, renderSize: renderSize, material: material, body: body as? LiquidBody) {
                    liquidNodes.append(node)
                }
            }
        default:
            break
        }
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
        renderDelegate?.updateRenderData(time: time)
        
        let cameraScale = renderDataSource?.cameraScale ?? 1
        let camera = SIMD2<Float32>(renderDataSource?.cameraX ?? 0, renderDataSource?.cameraY ?? 0)
        
        updateNodesIfNeeded()
        
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        let allTextures = allNodes.map { $0.render(commandBuffer: commandBuffer, cameraScale: cameraScale, camera: camera) }
        var textureCount = allTextures.count
        
        guard textureCount > 0 else { return }
//        print("[Renderer] texture count: \(textureCount)")
        
        _ = textureCountBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let textureCountBuffer = textureCountBufferProvider.nextUniformsBuffer(data: &textureCount, length: MemoryLayout<Int>.stride)
        
//        _ = timeBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
//        var timePassed: Float = 0//nextTime
//        let timeBuffer = timeBufferProvider.nextUniformsBuffer(data: &timePassed, length: MemoryLayout<Float>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.textureCountBufferProvider.avaliableResourcesSemaphore.signal()
//            self.timeBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        guard let mergeTexture = mergeTexture,
              let finalTexture = finalTexture,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor)
        else { return }
        
        computeEncoder.setComputePipelineState(mergePipelineState)
        computeEncoder.setTexture(mergeTexture, index: 0)
        computeEncoder.setTextures(allTextures, range: 1..<(textureCount + 1))
        computeEncoder.setBuffer(textureCountBuffer, offset: 0, index: 0)
        computeEncoder.setSamplerState(upscaleSamplerState, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: mergePipelineState, width: mergeTexture.width, height: mergeTexture.height)
        
        computeEncoder.setComputePipelineState(upscalePipelineState)
        computeEncoder.setTexture(mergeTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setSamplerState(upscaleSamplerState, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: upscalePipelineState, width: finalTexture.width, height: finalTexture.height)
        
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
        commandBuffer.commit()
    }
}
