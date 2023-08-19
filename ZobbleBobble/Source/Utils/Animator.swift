//
//  Animator.swift
//  ZobbleBobble
//
//  Created by Rost on 01.01.2023.
//

import Foundation

final class Animator {
    static func animate(duraion: Double, easing: Curve = .quadratic, step: @escaping (_ percentage: CGFloat) -> Void, completion: (() -> Void)? = nil) {
        let interval = 1.0 / 60.0
        let startDate = Date()
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            let timePassed = Date().timeIntervalSince(startDate)
            if timePassed > duraion {
                step(1.0)
                completion?()
                timer.invalidate()
                return
            }
            
            let percentage = applyEasing(to: timePassed / duraion, easing: easing)
            step(percentage)
        }
    }
    
    static private func applyEasing(to value: CGFloat, easing: Curve) -> CGFloat {
        easing.easeIn(value)
    }
}
