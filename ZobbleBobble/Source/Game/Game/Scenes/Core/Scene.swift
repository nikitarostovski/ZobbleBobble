//
//  Scene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

protocol GameInteractive: AnyObject {
    var player: PlayerModel { get }
    
//    func addPlanet(_ planet: PlanetModel)
//    func addContainer(_ container: ContainerModel)
//    func removeContainer(_ index: Int?)
//    func loadContainer(_ index: Int)
    
    func containerFinished()
}

protocol TransitionableSceneDelegate: AnyObject {
    func onTransitionableSceneAppendRequest(sender: Scene, becomesActive: Bool)
    func onTransitionableSceneRemovalRequest(sender: Scene)
}

class Scene {
    enum TransitionType {
        case toMe
        case fromMe
    }
    
    weak var transitionDelegate: TransitionableSceneDelegate?
    
    private(set) var size: CGSize
    private(set) var safeArea: CGRect
    private(set) var screenScale: CGFloat
    
    weak var game: GameInteractive?
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
    
    convenience init(_ scene: Scene) {
        self.init(game: scene.game, currentVisibility: scene.currentVisibility, size: scene.size, safeArea: scene.safeArea, screenScale: scene.screenScale)
    }
    
    init(game: GameInteractive?, currentVisibility: Float = 1, size: CGSize, safeArea: CGRect, screenScale: CGFloat) {
        self.game = game
        self.size = size
        self.safeArea = safeArea
        self.screenScale = screenScale
        
        setupLayout()
        updateLayout()
        
        updateVisibility(currentVisibility)
    }
    
    func setupLayout() { }
    
    func updateLayout() { }
    
    func onSizeChanged(_ newSize: CGSize, newSafeArea: CGRect, newScreenScale: CGFloat) {
        var needsLayout = false
        if size != newSize {
            needsLayout = true
            size = newSize
        }
        if safeArea != newSafeArea {
            needsLayout = true
            safeArea = newSafeArea
        }
        if newScreenScale != screenScale {
            needsLayout = true
            screenScale = newScreenScale
        }
        if needsLayout {
            updateLayout()
        }
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
            transitionDelegate?.onTransitionableSceneRemovalRequest(sender: self)
        }
        self.activeTransition = nil
    }
    
    func transition(to scene: Scene, becomesActive: Bool = true) throws {
        guard scene !== self else { throw TransitionError.unavailable }
        guard activeTransition == nil, scene.activeTransition == nil else { throw TransitionError.anotherTransitionInProgress }
        
        scene.transitionDelegate = transitionDelegate
        
        transitionDelegate?.onTransitionableSceneAppendRequest(sender: scene, becomesActive: becomesActive)
        
        let transition = SceneTransition(from: self,
                                         to: scene,
                                         duration: Settings.Camera.sceneTransitionDuration,
                                         curve: Settings.Camera.sceneTransitionEasing)
        
        self.activeTransition = transition
        scene.activeTransition = transition
        
        transition.start()
    }
    
    func hitTest(pos: CGPoint) -> Bool { userInteractionEnabled }
    
    @discardableResult
    func onTouchDown(pos: CGPoint) -> Bool {
        guard let gui = gui else { return false }
        let hit = gui.hitTest(pos: pos)
        gui.onTouchDown(pos: pos)
        return hit
    }
    
    @discardableResult
    func onTouchMove(pos: CGPoint) -> Bool {
        guard let gui = gui else { return false }
        let hit = gui.hitTest(pos: pos)
        gui.onTouchMove(pos: pos)
        return hit
    }
    
    @discardableResult
    func onTouchUp(pos: CGPoint) -> Bool {
        guard let gui = gui else { return false }
        let hit = gui.hitTest(pos: pos)
        gui.onTouchUp(pos: pos)
        return hit
    }
    
    func update(_ time: CFTimeInterval) { }
}

extension Scene {
    func goToContainerSelection() {
        let scene = ContainerSelectionScene(self)
        try? transition(to: scene)
    }
    
    func goToImprovements() {
        let scene = ImprovementsScene(self)
        try? transition(to: scene)
    }
    
    func goToControlCenter() {
        let scene = ControlCenterScene(self)
        try? transition(to: scene)
    }
    
    func goToUtilizationPlant() {
        let scene = UtilizationPlantScene(self)
        try? transition(to: scene)
    }
    
    func goToPlanetSelection() {
        let scene = PlanetSelectionScene(self)
        try? transition(to: scene)
    }
    
    func goToGarbageMarket() {
        let scene = GarbageMarketScene(self)
        try? transition(to: scene)
    }
    
    func goToBlackMarket() {
        let scene = BlackMarketScene(self)
        try? transition(to: scene)
    }
    
    func goToPlanet() {
        let scene = PlanetScene(self)
        try? transition(to: scene)
    }
    
    func goToGameResults() {
        let scene = GameResultsScene(self)
        try? transition(to: scene)
    }
}

extension Scene {
    var verticalScale: CGFloat { 1 / size.height * screenScale }
    var horizontalScale: CGFloat { 1 / size.width * screenScale }
    
    var buttonHeight: CGFloat { Constants.buttonHeight * verticalScale }
    var titleHeight: CGFloat { Constants.titleHeight * verticalScale }
    
    var paddingHorizontal: CGFloat { Constants.paddingHorizontal * horizontalScale }
    var paddingVertical: CGFloat { Constants.paddingVertical * verticalScale }
    
    enum Constants {
        static let buttonHeight: CGFloat = 60
        static let titleHeight: CGFloat = 60
        
        static let paddingHorizontal: CGFloat = 32
        static let paddingVertical: CGFloat = 16
    }
}
