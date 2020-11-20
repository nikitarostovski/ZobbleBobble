//
//  Renderer.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 18.11.2020.
//

import SpriteKit

final class Renderer: SKScene {
    
    private let cameraScale: CGFloat = 150
    private let cameraLimit: CGFloat = 0
    
    lazy var viewportNode: SKShapeNode = {
        let node = SKShapeNode()
        node.strokeColor = .cyan
        node.lineWidth = 2
        return node
    }()
    
    var viewport: CGSize {
        return CGSize(width: size.width, height: size.height)
    }
    var center: CGPoint {
        guard let playerNode = playerNode else { return CGPoint.zero }
        return CGPoint(x: playerNode.position.x + viewport.width * 0.5,
                       y: playerNode.position.y + viewport.height * 0.5)
    }
    
    let sceneNode: SKNode
    
    var playerNode: PlayerNode?
    var obstacleNodes: [ObstacleNode] = []
    
    weak var game: Game?
    
    var onUpdate: (() -> Void)?
    
    init(size: CGSize, game: Game) {
        self.game = game
        self.sceneNode = SKNode()
        
        super.init(size: size)
        
        addChild(sceneNode)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sceneNode.addChild(viewportNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        onUpdate?()
    }
    
    override func didFinishUpdate() {
        super.didFinishUpdate()
        
        viewportNode.path = CGPath(rect: CGRect(origin: CGPoint(x: center.x - viewport.width, y: center.y - viewport.height), size: viewport), transform: nil)
        
        guard let game = game else { return }
//        print("viewport: \(viewport) size: \(UIScreen.main.bounds.size)")
//        // Update camera
//        let scale: CGFloat = CGFloat(game.player.radius) / frame.width * cameraScale
//        let zoomInAction = SKAction.scale(to: scale, duration: 0)
////        playerCamera.run(zoomInAction)
//
//        if let playerNode = playerNode {
//            playerCamera.constraints = [.distance(.init(upperLimit: cameraLimit), to: playerNode)]
//        }
    }
    
    func update() {
        guard let game = game else { return }
        let playerNode = self.playerNode ?? PlayerNode(object: game.player)
        if self.playerNode == nil {
            self.playerNode = playerNode
            sceneNode.addChild(playerNode)
        }
        
        
        
        // remove old obstacles
        let actualIds = game.obstacles.map { $0.id }
        let toRemove = obstacleNodes.filter { node in
            guard let nodeId = node.id else { return true }
            return !actualIds.contains(nodeId)
        }
        toRemove.forEach { node in
            node.removeFromParent()
            obstacleNodes.removeAll(where: { $0 == node })
        }
        
        // add new obstacles
        game.obstacles.forEach { object in
            if !obstacleNodes.contains(where: { object.id == $0.id}) {
                
                let node = ObstacleNode(object: object)
                obstacleNodes.append(node)
                sceneNode.addChild(node)
            }
        }
        
        // update nodes
        obstacleNodes.forEach { node in
            node.update(with: game.obstacles.first(where: { $0.id == node.id }))
        }
        playerNode.update(with: game.player)
        sceneNode.position = CGPoint(x: -playerNode.position.x, y: -playerNode.position.y)
        
    }
}
