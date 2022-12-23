//
//  MetalRenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import UIKit
import MetalKit

final class MetalRenderView: MTKView, RenderView {
    lazy var renderer: Renderer = {
        let device = MTLCreateSystemDefaultDevice()!
        let renderer = Renderer(device: device, view: self)
        self.delegate = renderer
        return renderer
    }()
    
    func setRenderData(polygonMesh: PolygonMesh?, circleMesh: CircleMesh?, liquidMesh: LiquidMesh?) {
        renderer.setRenderData(polygonMesh: polygonMesh, circleMesh: circleMesh, liquidMesh: liquidMesh)
    }
    
    func setUniformData(particleRadius: Float) {
        renderer.setUniformData(particleRadius: particleRadius)
    }
}

class Renderer: NSObject, MTKViewDelegate {
    struct FragmentUniforms {
        let scaleX: Float
        let scaleY: Float
        let particleRadius: Float
    }
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let view: MTKView
    private var triangleRenderPipelineState: MTLRenderPipelineState!
    private var pointRenderPipelineState: MTLRenderPipelineState!
    private var liquidRenderPipelineState: MTLRenderPipelineState!
    private var uniformsBuffer: MTLBuffer?
    
    var polygonMesh: PolygonMesh?
    var circleMesh: CircleMesh?
    var liquidMesh: LiquidMesh?
    
    init(device: MTLDevice, view: MTKView) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        super.init()
        view.device = device
        view.delegate = self
        view.clearColor = MTLClearColor(red: 0,
                                        green: 0,
                                        blue: 0,
                                        alpha: 1)
        makePipeline()
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func setUniformData(particleRadius: Float) {
        var uniforms = FragmentUniforms(scaleX: 1.0 / Float(UIScreen.main.bounds.width),
                                        scaleY: 1.0 / Float(UIScreen.main.bounds.height),
                                        particleRadius: particleRadius)
        self.uniformsBuffer = device.makeBuffer(
            bytes: &uniforms,
            length: MemoryLayout<FragmentUniforms>.stride,
            options: [])!
    }
    
    func setRenderData(polygonMesh: PolygonMesh?, circleMesh: CircleMesh?, liquidMesh: LiquidMesh?) {
        self.polygonMesh = polygonMesh
        self.circleMesh = circleMesh
        self.liquidMesh = liquidMesh
        
        self.polygonMesh?.device = device
        self.circleMesh?.device = device
        self.liquidMesh?.device = device
    }
    
    func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        let triangleRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        triangleRenderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_triangle")!
        triangleRenderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_triangle")!
        triangleRenderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        do {
            triangleRenderPipelineState = try device.makeRenderPipelineState(descriptor: triangleRenderPipelineDescriptor)
        } catch {
            fatalError("Error while creating render pipeline state: \(error)")
        }
        
        let liquidRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        liquidRenderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_liquid")!
        liquidRenderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_liquid")!
        liquidRenderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        do {
            liquidRenderPipelineState = try device.makeRenderPipelineState(descriptor: liquidRenderPipelineDescriptor)
        } catch {
            fatalError("Error while creating render pipeline state: \(error)")
        }
        
        let pointRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        pointRenderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_point")!
        pointRenderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_point")!
        pointRenderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        do {
            pointRenderPipelineState = try device.makeRenderPipelineState(descriptor: pointRenderPipelineDescriptor)
        } catch {
            fatalError("Error while creating render pipeline state: \(error)")
        }
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let uniformsBuffer = uniformsBuffer else { return }
        
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        
        
        if let liquidMesh = liquidMesh, liquidMesh.vertexCount > 0 {
            renderCommandEncoder.setRenderPipelineState(liquidRenderPipelineState)
            renderCommandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)
            
            for (i, vertexBuffer) in liquidMesh.vertexBuffers.enumerated() {
                renderCommandEncoder.setVertexBuffer(vertexBuffer,
                                                     offset: 0,
                                                     index: i + 1)
            }
            renderCommandEncoder.drawPrimitives(type: liquidMesh.primitiveType,
                                                vertexStart: 0,
                                                vertexCount: liquidMesh.vertexCount)
        }
        
        if let circleMesh = circleMesh, circleMesh.vertexCount > 0 {
            renderCommandEncoder.setRenderPipelineState(pointRenderPipelineState)
            renderCommandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)
            
            for (i, vertexBuffer) in circleMesh.vertexBuffers.enumerated() {
                renderCommandEncoder.setVertexBuffer(vertexBuffer,
                                                     offset: 0,
                                                     index: i + 1)
            }
            renderCommandEncoder.drawPrimitives(type: circleMesh.primitiveType,
                                                vertexStart: 0,
                                                vertexCount: circleMesh.vertexCount)
        }
//        switch mesh.primitiveType {
//        case .triangle:
//            renderCommandEncoder.setRenderPipelineState(triangleRenderPipelineState)
//        case .point:
//            renderCommandEncoder.setRenderPipelineState(pointRenderPipelineState)
//        default:
//            return
//        }
//        renderCommandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)
//
//        for (i, vertexBuffer) in mesh.vertexBuffers.enumerated() {
//            renderCommandEncoder.setVertexBuffer(vertexBuffer,
//                                                 offset: 0,
//                                                 index: i + 1)
//        }
//        renderCommandEncoder.drawPrimitives(type: mesh.primitiveType,
//                                            vertexStart: 0,
//                                            vertexCount: mesh.vertexCount)
        
        renderCommandEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
