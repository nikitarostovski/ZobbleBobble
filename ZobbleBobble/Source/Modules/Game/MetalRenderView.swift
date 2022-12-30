//
//  MetalRenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import UIKit
import MetalKit

final class MetalRenderView: MTKView {
    let scale: CGFloat = 1//0.5
    var renderer: Renderer!
    
    var polygonMesh: PolygonMesh
    var circleMesh: CircleMesh
    var liquidMesh: LiquidMesh
    
    weak var dataSource: RenderDataSource?
    
    init() {
        let device = MTLCreateSystemDefaultDevice()!
        
        let size = CGSize(width: UIScreen.main.bounds.width / scale, height: UIScreen.main.bounds.height / scale)
//        let size = UIScreen.main.bounds.size
        
        self.polygonMesh = PolygonMesh(device)
        self.circleMesh = CircleMesh(device, size: size)
        self.liquidMesh = LiquidMesh(device, size: size)
        super.init(frame: .zero, device: device)
        self.renderer = Renderer(device: device, view: self)
        self.delegate = renderer
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(cameraScale: Float) {
        guard let dataSource = dataSource else { return }
        if let liquidCount = dataSource.liquidCount, let liquidPositions = dataSource.liquidPositions, let liquidVelocities = dataSource.liquidVelocities, let liquidColors = dataSource.liquidColors {
            self.liquidMesh.updateMeshIfNeeded(vertexCount: liquidCount, vertices: liquidPositions, velocities: liquidVelocities, colors: liquidColors, particleRadius: dataSource.particleRadius, cameraScale: cameraScale)
        }
        if let circleBodiesPositions = dataSource.circleBodiesPositions, let circleBodiesRadii = dataSource.circleBodiesRadii, let circleBodiesColors = dataSource.circleBodiesColors, let circleBodyCount = dataSource.circleBodyCount {
            self.circleMesh.updateMeshIfNeeded(positions: circleBodiesPositions, radii: circleBodiesRadii, colors: circleBodiesColors, count: circleBodyCount, cameraScale: cameraScale)
        }
        renderer.setRenderData(polygonMesh: polygonMesh, circleMesh: circleMesh, liquidMesh: liquidMesh)
    }
}

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var view: MTKView
    private var drawableRenderPipelineState: MTLRenderPipelineState!
    
    private var screenSizeBuffer: MTLBuffer?
    private var vertexBuffer: MTLBuffer?
    private var upscaleSamplerState: MTLSamplerState?
    private var vertexCount: Int = 0
    
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
        makePipeline()
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func setRenderData(polygonMesh: PolygonMesh?, circleMesh: CircleMesh?, liquidMesh: LiquidMesh?) {
        self.polygonMesh = polygonMesh
        self.circleMesh = circleMesh
        self.liquidMesh = liquidMesh
    }
    
    func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {
            return
        }
        let drawableRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        drawableRenderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_render")!
        drawableRenderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_render")!
        drawableRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        drawableRenderPipelineDescriptor.sampleCount = 1;
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
        
        var size: SIMD2<Float> = SIMD2<Float>(Float(UIScreen.main.bounds.size.width), Float(UIScreen.main.bounds.size.height))
        self.screenSizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<SIMD2<Float>>.stride)
        
        let s = MTLSamplerDescriptor()
//        s.magFilter = .nearest
        self.upscaleSamplerState = device.makeSamplerState(descriptor: s)
    }
    
//    var angle: Float = 0
    
    func draw(in view: MTKView) {
        self.view = view
        guard let drawableRenderPassDescriptor = view.currentRenderPassDescriptor else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let vertexBuffer = vertexBuffer, let upscaleSamplerState = upscaleSamplerState else { return }
        
        var liquidTexture: MTLTexture?
        if let liquidMesh = liquidMesh {
            liquidTexture = liquidMesh.render(commandBuffer: commandBuffer)
        }
        var circlesTexture: MTLTexture?
        if let circleMesh = circleMesh {
            circlesTexture = circleMesh.render(commandBuffer: commandBuffer)
        }
        
        
//        var angle = self.angle
//        let angleBuffer = device.makeBuffer(bytes: &angle, length: MemoryLayout<Float>.stride)!
//        self.angle += 0.01
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: drawableRenderPassDescriptor) else { return }
        renderEncoder.setRenderPipelineState(drawableRenderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//        renderEncoder.setVertexBuffer(angleBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(liquidTexture, index: 0)
        renderEncoder.setFragmentTexture(circlesTexture, index: 1)
        renderEncoder.setFragmentBuffer(screenSizeBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(upscaleSamplerState, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
