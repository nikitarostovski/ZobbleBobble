//
//  ContainerSelectionScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class ContainerSelectionScene: TransitionableScene {
    override var transitionTargetCategory: TransitionTarget { .containerSelection }
    
    private lazy var gui: GUIBody = {
        let body = GUIBody(buttons: [backButton, utilizationPlantButton, garbageMarketButton, planetSelectionButton], labels: [titleLabel])
        body.backgroundColor = Colors.GUI.Background.light
        return body
    }()
    
    private lazy var titleLabel: GUILabel = {
        let label = GUILabel(frame: CGRect(x: 0, y: 0.1, width: 1, height: 0.1))
        label.text = "Container selection"
        return label
    }()
    
    private lazy var utilizationPlantButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.1))
        button.tapAction = { [weak self] _ in try? self?.goToUtilizationPlant() }
        button.text = "Utilization plant"
        return button
    }()
    
    private lazy var garbageMarketButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.4, width: 0.5, height: 0.1))
        button.tapAction = { [weak self] _ in try? self?.goToGarbageMarket() }
        button.text = "Garbage market"
        return button
    }()
    
    private lazy var planetSelectionButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.65, width: 0.5, height: 0.1))
        button.tapAction = { [weak self] _ in try? self?.goToPlanetSelection() }
        button.text = "Planet selection"
        return button
    }()
    
    private lazy var backButton: GUIButton = {
        let button = GUIButton(frame: CGRect(x: 0.25, y: 0.8, width: 0.5, height: 0.1), style: .secondary)
        button.tapAction = { [weak self] _ in try? self?.goToControlCenter() }
        button.text = "Back"
        return button
    }()
    
    override var visibleBodies: [any Body] { [gui] }
    
    func goToControlCenter() throws {
        let scene = ControlCenterScene()
        try transition(to: scene)
    }
    
    func goToUtilizationPlant() throws {
        let scene = UtilizationPlantScene()
        try transition(to: scene)
    }
    
    func goToPlanetSelection() throws {
        let scene = PlanetSelectionScene()
        try transition(to: scene)
    }
    
    func goToGarbageMarket() throws {
        let scene = GarbageMarketScene()
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
