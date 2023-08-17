//
//  ControlCenterScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class ControlCenterScene: TransitionableScene {
    override var transitionTargetCategory: TransitionTarget { .controlCenter }
    
    private lazy var gui: GUIBody = {
        let body = GUIBody(buttons: [containerButton, improvementsButton], labels: [titleLabel])
        body.backgroundColor = Colors.GUI.Background.light
        return body
    }()
    
    private lazy var titleLabel: GUILabel = {
        let label = GUILabel(frame: CGRect(x: 0, y: 0.1, width: 1, height: 0.1))
        label.text = "Control center"
        return label
    }()
    
    private lazy var containerButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.65, width: 0.5, height: 0.1))
        button.text = "to container"
        button.tapAction = { [weak self] _ in try? self?.goToContainerSelection() }
        return button
    }()
    
    private lazy var improvementsButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.8, width: 0.5, height: 0.1))
        button.text = "improvements"
        button.tapAction = { [weak self] _ in try? self?.goToImprovements() }
        return button
    }()
    
    override var visibleBodies: [any Body] { [gui] }
    
    func goToContainerSelection() throws {
        let scene = ContainerSelectionScene()
        try transition(to: scene)
    }
    
    func goToImprovements() throws {
        let scene = ImprovementsScene()
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
