//
//  Scene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

protocol TransitionableSceneDelegate: AnyObject {
    func onTransitionableSceneAppendRequest(sender: Scene, becomesActive: Bool)
    func onTransitionableSceneRemovalRequest(sender: Scene)
}

class Scene {
    enum TransitionType {
        case toMe
        case fromMe
    }
    
    weak var delegate: TransitionableSceneDelegate?
    
    var userInteractionEnabled = false
    var transitionTargetCategory: TransitionTarget { .none }
    var visibleBodies: [any Body] { [] }
    
    private(set) var activeTransition: SceneTransition?
    private(set) var currentVisibility: Float = 0
    
    var activeTransitionTarget: TransitionTarget? {
        guard let transition = activeTransition else { return nil }
        if activeTransitionType == .toMe {
            return transition.from.transitionTargetCategory
        } else {
            return transition.to.transitionTargetCategory
        }
    }
    
    private var activeTransitionType: TransitionType? {
        activeTransition.map { $0.from === self ? .fromMe : .toMe }
    }
    private var activeTransitionScene: Scene? {
        activeTransition.map { $0.from === self ? $0.to : $0.from }
    }
    
    init(currentVisibility: Float = 1) {
        updateVisibility(currentVisibility)
    }
    
    /// Called when scene visibility should be changed. Do not override for scene updates. Use `updateForTransition`
    /// - Parameter progress: [0...1] float value. if 0 - scene is completely invisible, if 1 - scene is completelty visible
    /// - Parameter isFinished: true if this is the last call in current transition
    func onTransitionProgressChange(_ progress: Float, isFinished: Bool = false) {
        updateVisibility(progress, transitionTarget: activeTransitionTarget)
        
        if isFinished {
            onTransitionFinished()
        }
    }
    
    /// Override this method to implement custom scene transition behavior. Call super to save current visibility correctly
    /// - Parameters:
    ///   - visibility: Current scene visibility. [0...1]. If zero, current scene is presented 100%, other scene is 0% visible. if one then vice versa
    ///   - scene: other scene if there is a transition. nil if no transition is running
    func updateVisibility(_ visibility: Float, transitionTarget: TransitionTarget? = nil) {
        currentVisibility = visibility
        userInteractionEnabled = visibility + .leastNonzeroMagnitude >= 1
    }
    
    func onTransitionFinished() {
        if activeTransitionType == .fromMe {
            delegate?.onTransitionableSceneRemovalRequest(sender: self)
        }
        self.activeTransition = nil
    }
    
    func transition(to scene: Scene, becomesActive: Bool = true) throws {
        guard scene !== self else { throw TransitionError.unavailable }
        guard activeTransition == nil, scene.activeTransition == nil else { throw TransitionError.anotherTransitionInProgress }
        
        scene.delegate = delegate
        
        delegate?.onTransitionableSceneAppendRequest(sender: scene, becomesActive: becomesActive)
        
        let transition = SceneTransition(from: self,
                                         to: scene,
                                         duration: Settings.Camera.sceneTransitionDuration,
                                         curve: Settings.Camera.sceneTransitionEasing)
        
        self.activeTransition = transition
        scene.activeTransition = transition
        
        transition.start()
    }
    
    func hitTest(pos: CGPoint) -> Bool { userInteractionEnabled }
    func onTouchDown(pos: CGPoint) { }
    func onTouchMove(pos: CGPoint) { }
    func onTouchUp(pos: CGPoint) { }
    func update(_ time: CFTimeInterval) { }
}
