//
//  LiquidInstance.swift
//  ZobbleBobble
//
//  Created by Rost on 09.05.2023.
//

import MetalKit

class LiquidInstance: BaseMesh {
    let computePassDescriptor = MTLComputePassDescriptor()
    let metaballsRenderPassDescriptor = MTLRenderPassDescriptor()
    
    var pointCount = 0
    var mainColor: SIMD4<UInt8>
    
    var mainColorBuffer: MTLBuffer?
    var lowResSizeBuffer: MTLBuffer?
    
    var lowResAlphaTexture: MTLTexture?
    var finalAlphaCorrectedTexture: MTLTexture?
    var finalTexture: MTLTexture?
    
    private let screenSize: CGSize
    private let renderSize: CGSize
    
    init?(_ device: MTLDevice?, screenSize: CGSize, renderSize: CGSize, mainColor: SIMD4<UInt8>) {
        guard let device = device else { return nil }
        
        self.mainColor = mainColor
        
        self.screenSize = screenSize
        self.renderSize = renderSize
        
        self.mainColorBuffer = device.makeBuffer(bytes: &self.mainColor, length: MemoryLayout<SIMD4<UInt8>>.stride)
        
        
        let width = Int(renderSize.width * CGFloat(Settings.liquidMetaballsDownscale))
        let height = Int(renderSize.height * CGFloat(Settings.liquidMetaballsDownscale))
        guard width > 0, height > 0 else { return nil }
        
        var size: SIMD2<Float> = SIMD2<Float>(Float(width), Float(height))
        self.lowResSizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<SIMD2<Float>>.stride)
        
        super.init()
        self.device = device
        
        let lowResDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Unorm,
            width: width,
            height: height,
            mipmapped: false)
        lowResDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.lowResAlphaTexture = device.makeTexture(descriptor: lowResDesc)
        
        let finalDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(renderSize.width),
            height: Int(renderSize.height),
            mipmapped: false)
        finalDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.finalTexture = device.makeTexture(descriptor: finalDesc)
        
        let finalAlphaDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(renderSize.width),
            height: Int(renderSize.height),
            mipmapped: false)
        finalAlphaDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.finalAlphaCorrectedTexture = device.makeTexture(descriptor: finalAlphaDesc)
        
        metaballsRenderPassDescriptor.colorAttachments[0].loadAction = .load
        metaballsRenderPassDescriptor.colorAttachments[0].storeAction = .store
        metaballsRenderPassDescriptor.colorAttachments[0].texture = lowResAlphaTexture
        metaballsRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    func renderAlphaTexture(commandBuffer: MTLCommandBuffer,
                            uniformsBuffer: MTLBuffer,
                            positionBuffer: MTLBuffer,
                            velocityBuffer: MTLBuffer,
                            colorBuffer: MTLBuffer,
                            blurRadiusBuffer: MTLBuffer?,
                            metaballsPipelineState: MTLRenderPipelineState,
                            computeUpscalePipelineState: MTLComputePipelineState,
                            computeBlurPipelineState: MTLComputePipelineState,
                            linearSampler: MTLSamplerState,
                            pointCount: Int) -> (MTLTexture, MTLTexture)? {
        guard let lowResAlphaTexture = lowResAlphaTexture,
              let finalAlphaCorrectedTexture = finalAlphaCorrectedTexture
        else {
            return nil
        }

        let metaballsEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: metaballsRenderPassDescriptor)!
        metaballsEncoder.setRenderPipelineState(metaballsPipelineState)
        metaballsEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)
        metaballsEncoder.setVertexBuffer(positionBuffer, offset: 0, index: 1)
        metaballsEncoder.setVertexBuffer(velocityBuffer, offset: 0, index: 2)
        metaballsEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 3)
        metaballsEncoder.setVertexBuffer(lowResSizeBuffer, offset: 0, index: 4)
        metaballsEncoder.setVertexBuffer(mainColorBuffer, offset: 0, index: 5)
        metaballsEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: pointCount)
        metaballsEncoder.endEncoding()
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor)!
        
        if let blurRadiusBuffer = blurRadiusBuffer {
            computeEncoder.setComputePipelineState(computeBlurPipelineState)
            computeEncoder.setTexture(lowResAlphaTexture, index: 0)
            computeEncoder.setTexture(lowResAlphaTexture, index: 1)
            computeEncoder.setBuffer(blurRadiusBuffer, offset: 0, index: 0)
            ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: computeBlurPipelineState, width: lowResAlphaTexture.width, height: lowResAlphaTexture.height)
        }
        
        computeEncoder.setComputePipelineState(computeUpscalePipelineState)
        computeEncoder.setTexture(lowResAlphaTexture, index: 0)
        computeEncoder.setTexture(finalAlphaCorrectedTexture, index: 1)
        computeEncoder.setSamplerState(linearSampler, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: computeUpscalePipelineState, width: finalAlphaCorrectedTexture.width, height: finalAlphaCorrectedTexture.height)
        
        computeEncoder.endEncoding()
        return (lowResAlphaTexture, finalAlphaCorrectedTexture)
    }
    
    func renderFinalTexture(commandBuffer: MTLCommandBuffer,
                            fadeMultiplierBuffer: MTLBuffer,
                            initPipelineState: MTLComputePipelineState,
                            computeThresholdPipelineState: MTLComputePipelineState,
                            linearSampler: MTLSamplerState,
                            nearestSampler: MTLSamplerState) -> MTLTexture? {
        
        guard let finalAlphaCorrectedTexture = finalAlphaCorrectedTexture,
              let lowResAlphaTexture = lowResAlphaTexture,
              let finalTexture = finalTexture
        else {
            return nil
        }
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor)!

        computeEncoder.setComputePipelineState(computeThresholdPipelineState)
        computeEncoder.setTexture(finalAlphaCorrectedTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setBuffer(mainColorBuffer, offset: 0, index: 0)
        computeEncoder.setSamplerState(nearestSampler, index: 0)
        computeEncoder.setSamplerState(linearSampler, index: 1)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: computeThresholdPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(initPipelineState)
        computeEncoder.setTexture(lowResAlphaTexture, index: 0)
        computeEncoder.setTexture(lowResAlphaTexture, index: 1)
        computeEncoder.setBuffer(fadeMultiplierBuffer, offset: 0, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: initPipelineState, width: lowResAlphaTexture.width, height: lowResAlphaTexture.height)
        
        computeEncoder.endEncoding()
        return finalTexture
    }
}
