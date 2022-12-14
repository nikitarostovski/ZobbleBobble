//
//  GameViewController.swift
//  ZobbleBobble
//
//  Created by Rost on 02.12.2022.
//

import UIKit
import MetalKit

final class GameViewController2: UIViewController {
    var mtkView: MTKView { view as! MTKView }
    
    var world: PhysicsWorld!
    var renderer: Renderer!
    
    override func loadView() {
        self.view = MTKView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let device = MTLCreateSystemDefaultDevice()!
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
        
        renderer = Renderer(view: mtkView, device: device)
        mtkView.delegate = renderer
    }
}
