//
//  GUINode.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import MetalKit

class GUINode: BaseNode<GUIBody> {
    struct Uniforms {
        var alpha: Float
        let backgroundColor: SIMD4<UInt8>
    }
    
    private lazy var drawGUIPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "draw_gui")!)
    }()
    
    private let ciContext = CIContext()
    
    private let uniformsBufferProvider: BufferProvider
    private let rectsBufferProvider: BufferProvider
    private let rectCountBufferProvider: BufferProvider
    private let labelsBufferProvider: BufferProvider
    private let labelCountBufferProvider: BufferProvider
    
    private var sampler: MTLSamplerState?
    private var finalTexture: MTLTexture?
    private var textTextureCache = [GUIRenderData.TextRenderData: MTLTexture]()
    
    init(_ device: MTLDevice?, renderSize: CGSize, body: GUIBody?) {
        self.uniformsBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Uniforms>.stride)
        self.rectsBufferProvider = BufferProvider(device: device,
                                                    inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                    bufferSize: MemoryLayout<GUIRenderData.RectModel>.stride * GUIBody.maxRectCount)
        self.rectCountBufferProvider = BufferProvider(device: device,
                                                        inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                        bufferSize: MemoryLayout<Int32>.stride)
        self.labelsBufferProvider = BufferProvider(device: device,
                                                   inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                   bufferSize: MemoryLayout<GUIRenderData.LabelModel>.stride * GUIBody.maxLabelCount)
        self.labelCountBufferProvider = BufferProvider(device: device,
                                                       inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                       bufferSize: MemoryLayout<Int32>.stride)
        
        super.init()
        
        self.body = body
        self.device = device
        self.finalTexture = device?.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))
        self.sampler = device?.nearestSampler
    }
    
    override func render(commandBuffer: MTLCommandBuffer, cameraScale: Float, camera: SIMD2<Float>) -> MTLTexture? {
        let allTextTextures = buildTextTextures(body?.renderData?.textTexturesData, commandBuffer: commandBuffer)
        
        guard let body = body,
              var rectCount = body.renderData?.rectCount,
              var labelCount = body.renderData?.labelCount,
              let drawGUIPipelineState = drawGUIPipelineState,
              let finalTexture = finalTexture,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return nil
        }
        
        var uniforms = Uniforms(alpha: body.alpha, backgroundColor: body.backgroundColor)
        
        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)
        
        _ = rectsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let rectsBuffer = rectsBufferProvider.nextUniformsBuffer(data: body.renderData?.rects, length: MemoryLayout<GUIRenderData.RectModel>.stride * rectCount)
        
        _ = rectCountBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let rectCountBuffer = rectCountBufferProvider.nextUniformsBuffer(data: &rectCount, length: MemoryLayout<Int32>.stride)
        
        _ = labelsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let labelsBuffer = labelsBufferProvider.nextUniformsBuffer(data: body.renderData?.labels, length: MemoryLayout<GUIRenderData.LabelModel>.stride * labelCount)
        
        _ = labelCountBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let labelCountBuffer = labelCountBufferProvider.nextUniformsBuffer(data: &labelCount, length: MemoryLayout<Int32>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
            self.rectsBufferProvider.avaliableResourcesSemaphore.signal()
            self.rectCountBufferProvider.avaliableResourcesSemaphore.signal()
            self.labelsBufferProvider.avaliableResourcesSemaphore.signal()
            self.labelCountBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        computeEncoder.setComputePipelineState(drawGUIPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        if let allTextTextures = allTextTextures {
            computeEncoder.setTextures(allTextTextures, range: 1..<(allTextTextures.count + 1))
        }
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(rectsBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(rectCountBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(labelsBuffer, offset: 0, index: 3)
        computeEncoder.setBuffer(labelCountBuffer, offset: 0, index: 4)
        computeEncoder.setSamplerState(sampler, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: drawGUIPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}

// MARK: - Text

extension GUINode {
    private func buildTextTextures(_ array: [GUIRenderData.TextRenderData?]?, commandBuffer: MTLCommandBuffer) -> [MTLTexture?]? {
        return array?.map { [weak self] text -> MTLTexture? in
            guard let text = text else { return nil }
            return self?.buildTextTexture(text, commandBuffer: commandBuffer)
        }
    }
    
    private func buildTextTexture(_ text: GUIRenderData.TextRenderData, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        if let cached = textTextureCache[text] {
            return cached
        }

        guard let device = device,
              let filter = CIFilter(name: "CITextImageGenerator", parameters: [
                "inputText": text.text,
                "inputFontName": text.fontName,
                "inputFontSize": text.fontSize,
                "inputScaleFactor": 1.0
              ]),
              let textImage = filter.outputImage
        else { return nil }
        
        let texture = device.makeTexture(width: Int(textImage.extent.width), height: Int(textImage.extent.height))!
        ciContext.render(textImage,
                         to: texture,
                         commandBuffer: commandBuffer,
                         bounds: textImage.extent,
                         colorSpace: CGColorSpaceCreateDeviceRGB())
        textTextureCache[text] = texture
        return texture
    }
}
