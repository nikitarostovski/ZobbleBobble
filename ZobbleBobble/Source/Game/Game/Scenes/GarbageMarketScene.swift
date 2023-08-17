//
//  GarbageMarketScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class GarbageMarketScene: TransitionableScene {
    override var transitionTargetCategory: TransitionTarget { .garbageMarket }
    
    private lazy var gui: GUIBody = {
        let gui = GUIBody(buttons: [backButton], labels: [titleLabel])
        gui.backgroundColor = Colors.GUI.Background.dark
        return gui
    }()
    
    private lazy var titleLabel: GUILabel = {
        let label = GUILabel(frame: CGRect(x: 0, y: 0.1, width: 1, height: 0.1))
        label.text = "Garbage market"
        return label
    }()
    
    private lazy var backButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.8, width: 0.5, height: 0.1), style: .secondary)
        button.tapAction = { [weak self] _ in try? self?.goToContainerSelection() }
        button.text = "Back"
        return button
    }()
    
    override var visibleBodies: [any Body] { [gui] }
    
    func goToContainerSelection() throws {
        let scene = ContainerSelectionScene()
        try transition(to: scene)
    }
    
    override func updateVisibility(_ visibility: Float, transitionTarget: TransitionTarget? = nil) {
        super.updateVisibility(visibility, transitionTarget: transitionTarget)
        gui.alpha = visibility
    }
    
    override func onTouchDown(pos: CGPoint) {
        gui.onTouchDown(pos: pos)
    }
    
    override func onTouchMove(pos: CGPoint) {
        gui.onTouchMove(pos: pos)
    }
    
    override func onTouchUp(pos: CGPoint) {
        gui.onTouchUp(pos: pos)
    }
}
