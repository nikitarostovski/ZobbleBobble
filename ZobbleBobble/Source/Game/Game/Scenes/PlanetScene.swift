//
//  PlanetScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class PlanetScene: TransitionableScene {
    override var transitionTargetCategory: TransitionTarget { .planet }
    
    private lazy var gui: GUIBody = {
        let body = GUIBody(buttons: [controlCenterButton, gameResultsButton], labels: [titleLabel])
        body.backgroundColor = Colors.GUI.Background.dark
        return body
    }()
    
    private lazy var titleLabel: GUILabel = {
        let label = GUILabel(frame: CGRect(x: 0, y: 0.1, width: 1, height: 0.1))
        label.text = "Planet"
        return label
    }()
    
    private lazy var controlCenterButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.65, width: 0.5, height: 0.1), style: .secondary)
        button.tapAction = { [weak self] _ in try? self?.goToControlCenter() }
        button.text = "To control center"
        return button
    }()
    
    private lazy var gameResultsButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.8, width: 0.5, height: 0.1), style: .secondary)
        button.tapAction = { [weak self] _ in try? self?.goToGameResults() }
        button.text = "To game results"
        return button
    }()
    
    override var visibleBodies: [any Body] { [gui] }
    
    func goToControlCenter() throws {
        let scene = ControlCenterScene()
        try transition(to: scene)
    }
    
    func goToGameResults() throws {
        let scene = GameResultsScene()
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
