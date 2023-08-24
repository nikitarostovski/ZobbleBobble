//
//  SceneTransition.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import ScrollMechanics

enum TransitionError: Error {
    case unavailable
    case anotherTransitionInProgress
}

class SceneTransition {
    let duration: TimeInterval
    weak var from: Scene?
    weak var to: Scene?
    
    private var animation: TimerAnimation?
    
    init(from: Scene, to: Scene, duration: TimeInterval) {
        self.from = from
        self.to = to
        self.duration = duration
    }
    
    func start() {
        animation = TimerAnimation(duration: duration, animations: { [weak self] progress, time in
            guard let self = self else { return }
            
            let newFrom = Float(1 - progress)
            let newTo = Float(progress)
            
            from?.onTransitionProgressChange(newFrom)
            to?.onTransitionProgressChange(newTo)
        }, completion: { [weak self] f in
            
            guard let self = self else { return }
            from?.onTransitionProgressChange(0, isFinished: true)
            to?.onTransitionProgressChange(1, isFinished: true)
            animation?.invalidate()
            animation = nil
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
            newFrom = from?.opacity ?? 1
            newTo = to?.opacity ?? 0
        }
        from?.onTransitionProgressChange(newFrom, isFinished: true)
        to?.onTransitionProgressChange(newTo, isFinished: true)

        animation?.invalidate()
        animation = nil
    }
}
