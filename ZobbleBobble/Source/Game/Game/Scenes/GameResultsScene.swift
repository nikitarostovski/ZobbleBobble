//
//  GameResultsScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class GameResultsScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .gameResults }
    
    private lazy var gui: GUIBody = {
        let body = GUIBody(buttons: [controlCenterButton, improvementsButton], labels: [titleLabel])
        body.backgroundColor = Colors.GUI.Background.light
        return body
    }()
    
    private lazy var titleLabel: GUILabel = {
        let label = GUILabel(frame: CGRect(x: 0, y: 0.1, width: 1, height: 0.1))
        label.text = "Results"
        return label
    }()
    
    private lazy var controlCenterButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.8, width: 0.5, height: 0.1), style: .secondary)
        button.tapAction = { [weak self] _ in try? self?.goToControlCenter() }
        button.text = "To control center"
        return button
    }()
    
    private lazy var improvementsButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.65, width: 0.5, height: 0.1), style: .secondary)
        button.tapAction = { [weak self] _ in try? self?.goToImprovements() }
        button.text = "To Improvements"
        return button
    }()
    
    override var visibleBodies: [any Body] { [gui] }
    
    func goToControlCenter() throws {
        let scene = ControlCenterScene()
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
