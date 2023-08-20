//
//  SceneTransition.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

enum TransitionError: Error {
    case unavailable
    case anotherTransitionInProgress
}

class SceneTransition {
    let duration: TimeInterval
    let curve: Curve
    let from: Scene
    let to: Scene
    
    init(from: Scene, to: Scene, duration: TimeInterval, curve: Curve) {
        self.from = from
        self.to = to
        self.duration = duration
        self.curve = curve
    }
    
    func start() {
        Animator.animate(duraion: duration, easing: curve, step: { [weak self] percentage in
            guard let self = self else { return }
            
            let newFrom = Float(1 - percentage)
            let newTo = Float(percentage)
            
            self.from.onTransitionProgressChange(newFrom)
            self.to.onTransitionProgressChange(newTo)
            
        }, completion: { [weak self] in
            guard let self = self else { return }
            self.from.onTransitionProgressChange(0, isFinished: true)
            self.to.onTransitionProgressChange(1, isFinished: true)
        })
    }
    
    /// Stops current transition
    /// - Parameter shouldReset: if `true`, current transition progress resets to from scene, if `false`, it remains the same
    func stop(shouldReset: Bool = false) {
        let newFrom: Float
        let newTo: Float
        
        if shouldReset {
            // rewind back to `from` scene
            newFrom = 1
            newTo = 0
        } else {
            // finish transition immediately
            newFrom = from.opacity
            newTo = to.opacity
        }
        from.onTransitionProgressChange(newFrom, isFinished: true)
        to.onTransitionProgressChange(newTo, isFinished: true)
    }
}
