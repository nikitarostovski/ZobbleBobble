//
//  Level.swift
//  LevelDesign
//
//  Created by Rost on 17.03.2021.
//

import Foundation
import CoreGraphics

typealias Polygon = [CGPoint]

class Level: Codable {
    
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    var playerPosition: CGPoint?
    var exitPosition: CGPoint?
    
    var checkpoints = [CGPoint]()
    
    var polygons = [Polygon]() {
        didSet {
            updateSize()
        }
    }
    
    init(polygons: [Polygon] = []) {
        self.polygons = polygons
        updateSize()
    }
    
    private func updateSize() {
        var w: CGFloat = 0
        var h: CGFloat = 0
        
        self.polygons.forEach {
            w = max(w, $0.max(by: { $0.x > $1.x })?.x ?? 0)
            h = max(h, $0.max(by: { $0.y > $1.y })?.y ?? 0)
        }
        
        self.width = w + 1
        self.height = h + 1
    }
    
    static func load(json: Data) -> Self? {
        return try? JSONDecoder().decode(Self.self, from: json)
    }
    
    func save() -> String? {
        do {
            let jsonData = try JSONEncoder().encode(self)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            return jsonString
        } catch {
            print(error)
            return nil
        }
    }
}

extension Decodable {
    init(data: Data, using decoder: JSONDecoder = .init()) throws {
        self = try decoder.decode(Self.self, from: data)
    }
    init(json: String, using decoder: JSONDecoder = .init()) throws {
        try self.init(data: Data(json.utf8), using: decoder)
    }
}
