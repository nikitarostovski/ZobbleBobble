//
//  ImprovementsScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class ImprovementsScene: TransitionableScene {
    override var transitionTargetCategory: TransitionTarget { .improvements }
    
    private lazy var gui: GUIBody = {
        let body = GUIBody(buttons: [controlCenterButton], labels: [titleLabel])
        body.backgroundColor = Colors.GUI.Background.dark
        return body
    }()
    
    private lazy var titleLabel: GUILabel = {
        let label = GUILabel(frame: CGRect(x: 0, y: 0.1, width: 1, height: 0.1))
        label.text = "Improvements"
        return label
    }()
    
    private lazy var controlCenterButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.8, width: 0.5, height: 0.1), style: .secondary)
        button.tapAction = { [weak self] _ in try? self?.goToControlScene() }
        button.text = "Back"
        return button
    }()
    
    override var visibleBodies: [any Body] { [gui] }
    
    func goToControlScene() throws {
        let scene = ControlCenterScene()
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
