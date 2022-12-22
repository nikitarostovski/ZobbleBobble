//
//  CDT.swift
//  Delaunay
//
//  Created by Volodymyr Boichentsov on 14/11/2017.
//  Copyright © 2017 sakrist. All rights reserved.
//

import Foundation

/// Simply applying Constraines on result of Delauney Triangulation.  
public class CDT : Delaunay {
    
    override public func triangulate(_ vertices: [Point]) -> [Triangle] {
        return self.triangulate(vertices, nil)
    }
    
    public func triangulate(_ vertices: [Point], _ holesVertices:[[Point]]?) -> [Triangle] {
        
        var verticesCopy = vertices
        var holes = [TPolygon]()
        if let _holesVertices = holesVertices {
            for holeVertices in _holesVertices {
                verticesCopy.append(contentsOf: holeVertices)
                holes.append(TPolygon(holeVertices))
            }
        }
        
        let triangles = super.triangulate(verticesCopy)
        
        var trianglesCopy = [Triangle]()
        let polygon = TPolygon(vertices)
        
        // filter triangles by polygon and holes
        for item in triangles {
            var inHole = false 
            for hole in holes {
                if hole.contain(item.centroid) {
                    inHole = true
                    break
                }
            }
            if !inHole && polygon.contain(item.centroid) {
                trianglesCopy.append(item)
            }   
        }
        
        return trianglesCopy
    }
} 
