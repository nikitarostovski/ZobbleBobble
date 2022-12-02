//
//  GameViewController.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import UIKit
import SpriteKit

final class GameViewController: UIViewController {
    var scene: GameScene?
    
    lazy var sceneView: SKView = {
        let sceneView = SKView(frame: view.bounds)
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        sceneView.showsFields = true
        sceneView.ignoresSiblingOrder = true
        sceneView.showsPhysics = true
        sceneView.contentMode = .scaleToFill
        return sceneView
    }()
    
    lazy var resetButton: UIButton = {
        let b = UIButton()
        b.setTitle("Reset", for: .normal)
        b.backgroundColor = .blue
        b.setTitleColor(.white, for: .normal)
        b.addTarget(self, action: #selector(onResetTap), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
//    lazy var weaponPicker: WeaponPickerView = {
//        let picker = WeaponPickerView(frame: CGRect(x: 0, y: 0, width: 0, height: 80))
//        picker.translatesAutoresizingMaskIntoConstraints = false
//        picker.delegate = self
//        picker.weapons = WeaponType.allCases
//        return picker
//    }()
    
    lazy var gesture: UIGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(onTap(gr:)))
        g.delegate = self
        g.cancelsTouchesInView = false
        g.minimumPressDuration = 0
        return g
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(gesture)
        
        view.addSubview(sceneView)
        
//        view.addSubview(weaponPicker)
//        NSLayoutConstraint.activate([
//            NSLayoutConstraint(item: weaponPicker, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80),
//            NSLayoutConstraint(item: weaponPicker, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
//            NSLayoutConstraint(item: weaponPicker, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
//            NSLayoutConstraint(item: weaponPicker, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
//        ])
//        
//        view.addSubview(resetButton)
//        
//        NSLayoutConstraint.activate([
//            NSLayoutConstraint(item: resetButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80),
//            NSLayoutConstraint(item: resetButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50),
//            NSLayoutConstraint(item: resetButton, attribute: .bottom, relatedBy: .equal, toItem: weaponPicker, attribute: .top, multiplier: 1, constant: -12),
//            NSLayoutConstraint(item: resetButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
//        ])
        
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLoad()
        sceneView.frame = view.bounds
    }
    
    private func setup() {
        scene = GameScene(size: UIScreen.main.bounds.size)
        sceneView.presentScene(scene)
    }
    
    @objc
    private func onTap(gr: UIGestureRecognizer) {
//        guard let scene = scene else { return }
//        switch gr.state {
//        case .began:
//            scene.startFire()
//        case .cancelled, .ended, .failed:
//            scene.stopFire()
//        default:
//            break
//        }
    }
    
    @objc
    private func onResetTap() {
        setup()
    }
}

//extension GameViewController: WeaponPickerDelegate {
//    func weaponPickerDidChange(weapon: WeaponType) {
//        scene?.changeWeapon(to: weapon)
//    }
//}

extension GameViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touch.view == sceneView
    }
}
