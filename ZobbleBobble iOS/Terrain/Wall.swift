//
//  Wall.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import SpriteKit

class Wall: SKShapeNode {
    
    private var cell: Cell?
    
    weak var terrain: Terrain?
    
    static func make(from cell: Cell) -> Wall {
        var p = cell.polygon
        let node = Wall(points: &p, count: cell.polygon.count)
        node.cell = cell
        node.fillColor = UIColor(red: cell.color.r, green: cell.color.g, blue: cell.color.b, alpha: 0.5)
//        let node = Wall(splinePoints: &polygon, count: polygon.count)
        node.setupPhysics(points: p)
        return node
    }
    
    private func setupPhysics(points: [CGPoint]) {
        guard points.count > 2 else { return }
        
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        let body = SKPhysicsBody(polygonFrom: path)
        body.isDynamic = false
        body.friction = 10
        
        body.categoryBitMask = Category.wall.rawValue
        body.collisionBitMask = Category.unit.rawValue | Category.wall.rawValue
        body.contactTestBitMask = Category.missle.rawValue
        
        physicsBody = body
    }
    
    func startMonitoring() {
        let timer = Timer.init(timeInterval: 0.5, repeats: true) { [weak self] (timer) in
            guard let self = self else { return }
            
            func speed(_ velocity: CGVector) -> CGFloat {
                let dx = CGFloat(velocity.dx)
                let dy = CGFloat(velocity.dy)
                return sqrt(dx*dx+dy*dy)
            }

            func angularSpeed(_ velocity: CGFloat) -> CGFloat {
                return abs(CGFloat(velocity))
            }
            
            func stop() {
                timer.invalidate()
            }
            
            guard self.physicsBody != nil else { stop(); return }
            
            let smallValue: CGFloat = 0.1
            
            let isResting = (speed(self.physicsBody!.velocity) < smallValue
                                && angularSpeed(self.physicsBody!.angularVelocity) < smallValue)
            
            if isResting {
                self.physicsBody!.isDynamic = false
                self.strokeColor = .white
                stop()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
    
    public func explode(impulse: CGFloat, normal: CGVector, contactPoint: CGPoint) {
        let impulse = CGVector(dx: normal.dx * impulse, dy: normal.dy * impulse)
        
        guard let physicsBody = physicsBody,
              let terrain = terrain,
              let cells = cell?.split(impulse: impulse, point: contactPoint),
              !physicsBody.isDynamic
        else {
            return
        }
        
        let walls = cells.map { (cell) -> Wall in
            let wall = Self.make(from: cell)
            wall.physicsBody?.isDynamic = true
            wall.strokeColor = .red
            return wall
        }
        
        terrain.replace(wall: self, with: walls)
        
        walls.forEach {
            $0.physicsBody?.applyImpulse(impulse, at: contactPoint)
            $0.startMonitoring()
        }
    }
    
    public func destroy() {
        physicsBody = nil
        removeFromParent()
    }
}
