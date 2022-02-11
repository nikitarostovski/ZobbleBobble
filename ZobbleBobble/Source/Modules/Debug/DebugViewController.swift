//
//  DebugViewController.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 22.12.2021.
//

import UIKit

final class DebugViewController: UIViewController {
    private lazy var terrain: Terrain = {
        let t = TerrainGenerator.makeTerrain()
        return t
    }()
    
    private lazy var debugView: DebugDrawView = {
        let v = DebugDrawView()
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(debugView)
        
        debugView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(gr:))))
        
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] t in
            guard let self = self else { return }
            self.draw()
        }
        
        draw()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        debugView.frame = view.bounds
    }
    
    private func draw() {
        debugView.terrain = terrain
    }
    
    @objc
    private func onTap(gr: UITapGestureRecognizer) {
        let point = gr.location(in: debugView)
        if let chunk = debugView.chunkAt(point) {
            let newPolygons = chunk.globalPolygon.split()
            
            terrain.chunks.removeAll(where: { $0 === chunk })
            terrain.chunks.append(contentsOf: newPolygons.map { p in
                return Chunk(globalPolygon: p, material: chunk.material)
            })
        }
    }
}
