//
//  Renderer.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation
import MetalKit
import Levels

class Renderer: NSObject, MTKViewDelegate {
    weak var renderDelegate: RenderViewDelegate?
    weak var renderDataSource: RenderViewDataSource?
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var view: MTKView
    
    private var drawableRenderPipelineState: MTLRenderPipelineState!
    private var textureCountBufferProvider: BufferProvider
    private var vertexBuffer: MTLBuffer?
    private var upscaleSamplerState: MTLSamplerState?
    private var vertexCount: Int = 0
    
    private let renderSize: CGSize
    private let screenSize: CGSize
    
    private var lastDrawDate: Date?
    
    private var starNodes = [StarNode]()
    private var liquidNodes = [LiquidNode]()
    
    private var allNodes: [Node] {
        starNodes + liquidNodes
    }
    
    init(device: MTLDevice, view: MTKView, renderSize: CGSize, screenSize: CGSize, delegate: RenderViewDelegate?, dataSource: RenderViewDataSource?) {
        self.screenSize = screenSize
        self.renderSize = renderSize
        self.device = device
        self.renderDelegate = delegate
        self.renderDataSource = dataSource
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        self.textureCountBufferProvider = BufferProvider(device: device,
                                                         inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                         bufferSize: MemoryLayout<Int>.stride)
        super.init()
        view.device = device
        view.delegate = self
        
        setupPipeline()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
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
        
        let s = MTLSamplerDescriptor()
        s.magFilter = .nearest
        s.minFilter = .nearest
        self.upscaleSamplerState = device.makeSamplerState(descriptor: s)
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
        updateNodesIfNeeded()
        
        self.view = view
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        let cameraScale = renderDataSource?.cameraScale ?? 1
        let camera = SIMD2<Float32>(renderDataSource?.cameraX ?? 0, renderDataSource?.cameraY ?? 0)
        
        let allTextures = allNodes.map { $0.render(commandBuffer: commandBuffer, cameraScale: cameraScale, camera: camera) }
        var textureCount = allTextures.count
//        print("[Renderer] texture count: \(textureCount)")
        
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
