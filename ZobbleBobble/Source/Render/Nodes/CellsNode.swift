//
//  CellsNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 12.09.2023.
//

import MetalKit
import MetalPerformanceShaders

class CellsNode: BaseNode<TerrainBody> {
    struct Uniforms { }
    
    private lazy var initPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "fade_out")!)
    }()
    
    private lazy var drawCellsPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "draw_cells")!)
    }()
    
    private lazy var upscalePipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "upscale_texture")!)
    }()
    
    let uniformsBufferProvider: BufferProvider
    let fadeMultiplierBufferProvider: BufferProvider
    
    var fadeMultiplier: Float = 0
    
    let renderSize: CGSize
    
    var upscaleSampler: MTLSamplerState?
    var lowResTexture: MTLTexture?
    var finalTexture: MTLTexture?
    
    init?(_ device: MTLDevice?, renderSize: CGSize, body: TerrainBody?) {
        self.uniformsBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Uniforms>.stride)
        self.fadeMultiplierBufferProvider = BufferProvider(device: device,
                                                           inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                           bufferSize: MemoryLayout<Float>.stride)
        
        self.renderSize = renderSize
        
        let height = Int(Settings.Camera.sceneHeight)
        let width = Int(renderSize.width * CGFloat(height) / renderSize.height)
        
        guard width > 0, height > 0, let device = device else { return nil }
        
        super.init()
        
        self.body = body
        self.device = device
        
        self.lowResTexture = device.makeTexture(width: width, height: height)
        self.finalTexture = device.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))
        self.upscaleSampler = device.nearestSampler
    }
    
    override func render(commandBuffer: MTLCommandBuffer,
                         cameraScale: Float32,
                         camera: SIMD2<Float32>) -> MTLTexture? {
        
        guard let renderData = body?.renderData else { return nil }
        
        var uniforms = Uniforms()
        
        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)
        
        _ = fadeMultiplierBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let fadeMultiplierBuffer = fadeMultiplierBufferProvider.nextUniformsBuffer(data: &fadeMultiplier,
                                                                         length: MemoryLayout<Float>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
            self.fadeMultiplierBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        guard let initPipelineState = initPipelineState,
              let drawCellsPipelineState = drawCellsPipelineState,
              let upscalePipelineState = upscalePipelineState,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
              let lowResTexture = lowResTexture,
              let finalTexture = finalTexture
        else {
            return nil
        }
        
        computeEncoder.setComputePipelineState(drawCellsPipelineState)
        computeEncoder.setTexture(renderData.gridTexture, index: 0)
        computeEncoder.setTexture(lowResTexture, index: 1)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: drawCellsPipelineState, width: lowResTexture.width, height: lowResTexture.height)
        
        computeEncoder.setComputePipelineState(upscalePipelineState)
        computeEncoder.setTexture(lowResTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setSamplerState(upscaleSampler, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: upscalePipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(initPipelineState)
        computeEncoder.setTexture(lowResTexture, index: 0)
        computeEncoder.setTexture(lowResTexture, index: 1)
        computeEncoder.setBuffer(fadeMultiplierBuffer, offset: 0, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: initPipelineState, width: lowResTexture.width, height: lowResTexture.height)
        
        computeEncoder.endEncoding()
        return finalTexture
    }
}
