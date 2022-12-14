//
//  Renderer.swift
//  ZobbleBobble
//
//  Created by Rost on 02.12.2022.
//

import UIKit
import MetalKit

struct Vertex {
    let x: Float
    let y: Float
    let r: Float
    let g: Float
    let b: Float
    let a: Float
}

class Renderer: NSObject {
    let device: MTLDevice
    let view: MTKView
    let commandQueue: MTLCommandQueue
    
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
     
    init(view: MTKView, device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        super.init()
        
        view.device = device
        view.delegate = self
        view.clearColor = MTLClearColor(red: 0.95,
                                        green: 0.95,
                                        blue: 0.95,
                                        alpha: 1.0)
        makePipeline()
        makeResources()
    }
    
    func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")!
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")!
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        
        
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 6
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            fatalError("Error while creating render pipeline state: \(error)")
        }
    }
    
    func makeResources() {
        var vertexData: [Vertex] = [
            Vertex(x: -0.8, y: -0.8, r: 1, g: 0, b: 0, a: 1),
            Vertex(x:  0.8, y:  0.8, r: 0, g: 1, b: 0, a: 1),
            Vertex(x:  0.8, y: -0.8, r: 0, g: 0, b: 1, a: 1)
        ]
        
        vertexBuffer = device.makeBuffer(bytes: &vertexData,
                                         length: MemoryLayout<Vertex>.stride * vertexData.count,
                                         options: .storageModeShared)
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(vertexBuffer,
                                             offset: 0,
                                             index: 0)
        
        renderCommandEncoder.drawPrimitives(type: .point,
                                            vertexStart: 0,
                                            vertexCount: 3)
        
        renderCommandEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
