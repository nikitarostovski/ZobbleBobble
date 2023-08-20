//
//  SceneRenderer.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation
import MetalKit
import MetalPerformanceShaders
import Levels

class SceneRenderer {
    weak var scene: Scene?
    
    private let device: MTLDevice
    
    private var fillColorPipelineState: MTLComputePipelineState!
    private var mergePipelineState: MTLComputePipelineState!
    private var upscalePipelineState: MTLComputePipelineState!
    private var alphaMultiplyPipelineState: MTLComputePipelineState!
    
    private var textureCountBufferProvider: BufferProvider!
    private var backgroundColorBufferProvider: BufferProvider!
    private var alphaBufferProvider: BufferProvider!
    private var blendModeBuffer: MTLBuffer?
    private var upscaleSamplerState: MTLSamplerState?
    
    private var finalTexture: MTLTexture?
    private var mergeTexture: MTLTexture?
    
    /// Blending mode for texture merge shader. Look at `blend` shader method for details
    private var blendMode: Int32 = 1
    /// Final size of drawable presented
    private var renderSize: CGSize
    /// Size of downscaled gameplay texture
    private var gameTextureSize: CGSize
    
    private var liquidNodes = [LiquidNode]()
    private var gunNodes = [GunNode]()
    private var guiNodes = [GUINode]()
    
    private var allNodes: [Node] {
        liquidNodes + gunNodes + guiNodes
    }
    
    init(scene: Scene?, device: MTLDevice, renderSize: CGSize, gameTextureSize: CGSize) {
        self.device = device
        self.scene = scene
        self.renderSize = renderSize
        self.gameTextureSize = gameTextureSize

        setupPipeline()
        updateNodesIfNeeded()
    }
    
    func render(_ commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        guard let scene = scene else { return nil }
        
        let allTextures = [finalTexture] + allNodes.map { $0.render(commandBuffer: commandBuffer, cameraScale: scene.cameraScale, camera: scene.camera) }
        var textureCount = allTextures.count
        
        guard textureCount > 0 else { return nil }
        
        _ = textureCountBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let textureCountBuffer = textureCountBufferProvider.nextUniformsBuffer(data: &textureCount, length: MemoryLayout<Int>.stride)
        
        _ = alphaBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let alphaBuffer = alphaBufferProvider.nextUniformsBuffer(data: &scene.opacity, length: MemoryLayout<Float32>.stride)
        
        _ = backgroundColorBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let backgroundColorBuffer = backgroundColorBufferProvider.nextUniformsBuffer(data: &scene.background, length: MemoryLayout<SIMD4<UInt8>>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.textureCountBufferProvider.avaliableResourcesSemaphore.signal()
            self.alphaBufferProvider.avaliableResourcesSemaphore.signal()
            self.backgroundColorBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        guard let finalTexture = finalTexture,
              let mergePipelineState = mergePipelineState,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else { return nil }
        
        computeEncoder.setComputePipelineState(fillColorPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setBuffer(backgroundColorBuffer, offset: 0, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: fillColorPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(mergePipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTextures(allTextures, range: 1..<(textureCount + 1))
        computeEncoder.setBuffer(textureCountBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(blendModeBuffer, offset: 0, index: 1)
        computeEncoder.setSamplerState(upscaleSamplerState, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: mergePipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(upscalePipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setSamplerState(upscaleSamplerState, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: upscalePipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(alphaMultiplyPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setBuffer(alphaBuffer, offset: 0, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: alphaMultiplyPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
    
    private func setupPipeline() {
        guard let library = device.makeDefaultLibrary() else { return }
        
        textureCountBufferProvider = BufferProvider(device: device,
                                                    inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                    bufferSize: MemoryLayout<Int>.stride)
        
        alphaBufferProvider = BufferProvider(device: device,
                                             inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                             bufferSize: MemoryLayout<Float32>.stride)
        
        backgroundColorBufferProvider = BufferProvider(device: device,
                                                       inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                       bufferSize: MemoryLayout<SIMD4<UInt8>>.stride)
        upscaleSamplerState = device.nearestSampler
        finalTexture = device.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))

        do {
            fillColorPipelineState = try device.makeComputePipelineState(function: library.makeFunction(name: "fill_color")!)
            mergePipelineState = try device.makeComputePipelineState(function: library.makeFunction(name: "merge")!)
            alphaMultiplyPipelineState = try device.makeComputePipelineState(function: library.makeFunction(name: "alpha_multiply")!)
            upscalePipelineState = try device.makeComputePipelineState(function: library.makeFunction(name: "upscale_texture")!)
        } catch {
            print(error)
        }
        blendModeBuffer = device.makeBuffer(bytes: &blendMode, length: MemoryLayout<Int32>.stride)
    }
    
    private func updateNodesIfNeeded() {
        guard let bodies = scene?.visibleBodies else { return }
        
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
                liquidNodes.removeAll(where: { $0 === node })
                guiNodes.removeAll(where: { $0 === node })
                gunNodes.removeAll(where: { $0 === node })
            }
        }
    }
    
    private func addNode(for body: any Body) {
        switch body {
        case is GunBody:
            let node = GunNode(device, renderSize: gameTextureSize, body: body as? GunBody)
            gunNodes.append(node)
        case is LiquidBody:
            for material in body.uniqueMaterials {
                if let node = LiquidNode(device, renderSize: gameTextureSize, material: material, body: body as? LiquidBody) {
                    liquidNodes.append(node)
                }
            }
        case is GUIBody:
            let node = GUINode(device, renderSize: renderSize, body: body as? GUIBody)
            guiNodes.append(node)
        default:
            break
        }
    }
}
