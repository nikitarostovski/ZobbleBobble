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
    
    var size: CGSize
    var safeArea: CGRect
    
    var gui: GUIBody?
    var background: SIMD4<UInt8> = .zero
    
    var userInteractionEnabled = false
    var transitionTargetCategory: TransitionTarget { .none }
    var visibleBodies: [any Body] { [gui].compactMap { $0 } }
    
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
    
    init(currentVisibility: Float = 1, size: CGSize, safeArea: CGRect) {
        self.size = size
        self.safeArea = safeArea
        setupLayout()
        onSizeChanged(size, newSafeArea: safeArea)
        updateVisibility(currentVisibility)
    }
    
    func setupLayout() { }
    
    func updateLayout() { }
    
    func onSizeChanged(_ newSize: CGSize, newSafeArea: CGRect) {
        if size != newSize {
            size = newSize
        }
        if safeArea != newSafeArea {
            safeArea = newSafeArea
        }
        updateLayout()
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
        gui?.alpha = visibility
        background.w = UInt8(255 * visibility)
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
    
    func onTouchDown(pos: CGPoint) {
        gui?.onTouchDown(pos: pos)
    }
    
    func onTouchMove(pos: CGPoint) {
        gui?.onTouchMove(pos: pos)
    }
    
    func onTouchUp(pos: CGPoint) {
        gui?.onTouchUp(pos: pos)
    }
    
    func update(_ time: CFTimeInterval) { }
}

extension Scene {
    func goToContainerSelection() {
        let scene = ContainerSelectionScene(size: size, safeArea: safeArea)
        try? transition(to: scene)
    }
    
    func goToImprovements() {
        let scene = ImprovementsScene(size: size, safeArea: safeArea)
        try? transition(to: scene)
    }
    
    func goToControlCenter() {
        let scene = ControlCenterScene(size: size, safeArea: safeArea)
        try? transition(to: scene)
    }
    
    func goToUtilizationPlant() {
        let scene = UtilizationPlantScene(size: size, safeArea: safeArea)
        try? transition(to: scene)
    }
    
    func goToPlanetSelection() {
        guard let scene = PlanetSelectionScene(size: size, safeArea: safeArea) else { return }
        try? transition(to: scene)
    }
    
    func goToGarbageMarket() {
        let scene = GarbageMarketScene(size: size, safeArea: safeArea)
        try? transition(to: scene)
    }
    
    func goToBlackMarket() {
        let scene = BlackMarketScene(size: size, safeArea: safeArea)
        try? transition(to: scene)
    }
    
    func goToPlanet(_ planet: PlanetModel, player: PlayerModel) {
        let scene = PlanetScene(size: size, safeArea: safeArea, planet: planet, player: player)
        try? transition(to: scene)
    }
    
    func goToGameResults() {
        let scene = GameResultsScene(size: size, safeArea: safeArea)
        try? transition(to: scene)
    }
}

extension Scene {
    enum Constants {
        static let buttonHeight: CGFloat = 120
        static let titleHeight: CGFloat = 80
        
        static let paddingHorizontal: CGFloat = 64
        static let paddingVertical: CGFloat = 32
    }
}
