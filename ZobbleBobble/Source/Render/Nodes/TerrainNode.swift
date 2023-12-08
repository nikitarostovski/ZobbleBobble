//
//  TerrainNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 26.09.2023.
//

import MetalKit
import MetalPerformanceShaders
import ZobblePhysics

class TerrainNode: BaseNode<LiquidBody> {
    struct Uniforms {
        let cameraScale: Float32
        let camera: SIMD2<Float32>
    }
    
    struct Particle {
        let lastPos: SIMD2<Float>
        let pos: SIMD2<Float>
        let acc: SIMD2<Float>
//        let lastPos: SIMD2<Float>
    }
    
    private lazy var drawPipelineState: MTLComputePipelineState? = {
        try! device!.makeComputePipelineState(function: device!.makeDefaultLibrary()!.makeFunction(name: "draw_terrain")!)
    }()
    
    private lazy var clearPipelineState: MTLComputePipelineState? = {
        try! device!.makeComputePipelineState(function: device!.makeDefaultLibrary()!.makeFunction(name: "clear_terrain")!)
    }()
    
    let particleBufferProvider: BufferProvider
    let uniformsBufferProvider: BufferProvider
    
    var particleBuffer: MTLBuffer?
    var particleCount: Int = 0
    
    var finalTexture: MTLTexture?
    var uniforms: Uniforms
    let renderSize: CGSize
    
    init?(_ device: MTLDevice?, renderSize: CGSize, body: LiquidBody?) {
        self.particleBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Particle>.stride * Settings.Physics.maxParticleCount)
        self.uniformsBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Uniforms>.stride)
        
        self.renderSize = renderSize
        self.uniforms = .init(cameraScale: 1, camera: .zero)
        
        super.init()
        
        self.body = body
        if let body = body as? TerrainBody {
            body.delegate = self
        }
        self.device = device
        self.finalTexture = device?.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))
    }
    
    override func render(commandBuffer: MTLCommandBuffer,
                         cameraScale: Float32,
                         camera: SIMD2<Float32>) -> MTLTexture? {
        
        if !(body is TerrainBody), let renderData = body?.renderData {
            updateParticleBuffer(from: renderData.particles, particleCount: renderData.count)
        }
        
        guard let particleBuffer = particleBuffer, particleCount > 0 else { return nil }
        self.uniforms = .init(cameraScale: cameraScale, camera: camera)
        
        var uniforms = Uniforms(cameraScale: cameraScale, camera: camera)

        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)

        
        commandBuffer.addCompletedHandler { _ in
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
        }

        guard let drawPipelineState = drawPipelineState, let clearPipelineState = clearPipelineState else {
            return nil
        }
        
        guard let finalTexture = finalTexture,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return finalTexture
        }

        computeEncoder.setComputePipelineState(clearPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: clearPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(drawPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 1)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: drawPipelineState, width: particleCount, height: 1)

        computeEncoder.endEncoding()
        return finalTexture
    }
}

extension TerrainNode: TerrainBodyDelegate {
    func terrainBodyDidUpdate(particles: UnsafeRawPointer?, particleCount: Int) {
        updateParticleBuffer(from: particles, particleCount: particleCount)
    }
    
    private func updateParticleBuffer(from particles: UnsafeRawPointer?, particleCount: Int) {
        guard let particles = particles, particleCount > 0 else { return }
        
        let bufferSize = MemoryLayout<Particle>.stride * particleCount
        let buffer = device?.makeBuffer(bytes: particles, length: bufferSize)
        
        self.particleBuffer = buffer
        self.particleCount = particleCount
    }
}
