//
//  World.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit
import ZobbleCore
import ZobblePhysics

final class World: SKNode {
    private let particleRadius: CGFloat = 10
    
    var world: ZPWorld
    
    private var levelNode: LevelNode!
    
    var cameraCenter: CGPoint {
        let bounds = playerNode.boundingBox
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    var cameraScale: CGFloat = 1
    
    var targetCameraScale: CGFloat {
        let bounds = playerNode.boundingBox
        let xScale = bounds.width / worldSize.width * 2
        let yScale = bounds.height / worldSize.height * 2
        
        let scale = max(xScale, yScale)
        return scale
    }
    
    var worldSize: CGSize { UIScreen.main.bounds.size }
    
    lazy var playerNode: LiquidNode = {
        let points = Polygon.make(radius: 50, position: CGPoint(x: 80, y: 10), vertexCount: 8)
        let node = LiquidNode(world: self, body: points, color: .red, particleRadius: particleRadius)
        return node
    }()
    
    
    var viewportBoundsNode: SKShapeNode?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(level: Level, camera: SKCameraNode) {
        self.world = ZPWorld(gravity: CGPoint(x: 0, y: -10), particleRadius: particleRadius)
        super.init()
        
        levelNode = LevelNode(world: self, level: level)
        addChild(levelNode)
        
        addChild(camera)
        
        camera.addChild(playerNode)
        
//        let n = SKShapeNode(rectOf: .zero)
//        viewportBoundsNode = n
//        addChild(n)
        
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update(displayLink:)))
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: .current, forMode: .default)
    }
    
    func updateCamera(camera: SKCameraNode) {
        camera.position = cameraCenter
        
        let cameraScale = cameraScale
        camera.xScale = cameraScale
        camera.yScale = cameraScale
    }
    
    @objc
    private func update(displayLink: CADisplayLink) {
        autoreleasepool {
            world.worldStep(displayLink.duration, velocityIterations: 6, positionIterations: 2)
        }
        let viewportSize = CGSize(width: worldSize.width * cameraScale, height: worldSize.height * cameraScale)
        
        levelNode.updateViewport(center: cameraCenter, size: viewportSize)
//        playerNode.updateViewport(center: cameraCenter, size: viewportSize)
        
        cameraScale = targetCameraScale//cameraScale + (targetCameraScale - cameraScale) * 0.01
        
        viewportBoundsNode?.path = CGPath(rect: CGRect(origin: .zero, size: viewportSize), transform: nil)
        viewportBoundsNode?.position = CGPoint(x: cameraCenter.x - viewportSize.width / 2, y: cameraCenter.y - viewportSize.height / 2)
    }
}
