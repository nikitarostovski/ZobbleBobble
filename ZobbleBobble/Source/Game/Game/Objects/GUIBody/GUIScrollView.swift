//
//  GUIScrollView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.08.2023.
//

import Foundation
import ScrollMechanics

class GUIScrollView: GUIView {
    typealias ScrollClosure = (GUIScrollView) -> Void
    
    private enum State {
        case `default`
        case dragging(initialOffset: CGPoint)
    }
    
    // scroll deceleration
    let decelerationRate: CGFloat = 0.999
    // Maximum pages to scroll over
    let pageScrollLimit: CGFloat = 1
    // Minimum page distance to traverse to swipe
    let swipeThreshold: CGFloat = 0.3
    /// Minimum time in seconds for gesture to last to cause deceleration pagination behavior
    let gestureCompletionThreshold: CGFloat = 0.1
    
    private var startPoint: CGPoint?
    private var startPointTime: TimeInterval?
    
    private var lastPoint: CGPoint?
    private var lastPointTime: TimeInterval?
    private var lastPan: Date?
    private var lastVelocity: CGPoint = .zero
    
    private var state: State = .default
    private var contentOffsetAnimation: TimerAnimation?
    private var offset: CGPoint = .zero { didSet { needsDisplay = true; onScroll?(self) } }
    private var subviewRenderDataCahce: RenderData?
    
    var onScroll: ScrollClosure?
    var contentSize = CGSize(width: 1, height: 1) { didSet { needsDisplay = true; onScroll?(self) } }
    
    var contentOffset: CGPoint {
        get { CGPoint(x: -offset.x, y: offset.y) }
        set { offset = CGPoint(x: -newValue.x, y: newValue.y) }
    }
    
    private var contentOffsetBounds: CGRect {
        let width = -(contentSize.width - bounds.width)
        let height = contentSize.height - bounds.height
        return CGRect(x: 0, y: 0, width: width, height: height)
    }
    
    override func layout() {
        super.layout()
        onScroll?(self)
    }
    
    override func onTouchDown(pos: CGPoint) -> Bool {
        let newPan = Date()
        startPoint = pos
        startPointTime = newPan.timeIntervalSince1970
        
        stopOffsetAnimation()
        state = .dragging(initialOffset: offset)
        
        lastPan = newPan
        lastPoint = nil
        lastPointTime = nil
        return true
    }
    
    override func onTouchMove(pos: CGPoint) -> Bool {
        guard let startPoint = startPoint else { return false }
        let newPan = Date()
        let translation = (pos - startPoint)
        
        var newOffset: CGPoint = .zero
        if case .dragging(let initialOffset) = state {
            newOffset = translation + initialOffset
            offset = clampOffset(newOffset)
        }
        lastPan = newPan
        
        if let lastPoint = lastPoint, let lastPointTime = lastPointTime {
            let time = (newPan.timeIntervalSince1970 - lastPointTime)
            let dist = CGPoint(x: newOffset.x - lastPoint.x,
                               y: newOffset.y - lastPoint.y)
            self.lastVelocity = dist / time
        }
        
        if lastPoint != pos {
            lastPoint = newOffset
            lastPointTime = newPan.timeIntervalSince1970
        }
        needsDisplay = true
        return true
    }
    
    override func onTouchUp(pos: CGPoint) -> Bool {
        let newPan = Date()
        
        let nowTime = newPan.timeIntervalSince1970
        let gestureDuration = nowTime - (startPointTime ?? nowTime)
        
        let userHadStoppedDragging = newPan.timeIntervalSince(lastPan ?? newPan) >= 0.1
        let gestureDurationWasEnough = gestureDuration > gestureCompletionThreshold
        let velocity = userHadStoppedDragging ? .zero : (gestureDurationWasEnough ? lastVelocity : .zero)
        
        completeGesture(withVelocity: velocity)
        state = .default
        
        lastPan = newPan
        
        startPoint = nil
        startPointTime = nil
        return true
    }
    
    override func makeSubviewsRenderData() -> RenderData {
        guard needsDisplay else { return subviewRenderDataCahce ?? super.makeSubviewsRenderData() }
        
        var result = RenderData([], [])
        
        var rects = [GUIRenderData.RectModel]()
        var labels = [(GUIRenderData.LabelModel, GUIRenderData.TextRenderData)]()
        
        let allRenderData = subviews.map { $0.makeRenderData() }
        
        allRenderData.forEach { rectsRenderData, labelsRenderData in
            let shift = Float(offset.x)
            let rectsRenderData = rectsRenderData.compactMap {
                var data = $0;
                data.origin.x += Float(frame.origin.x)
                data.origin.y += Float(frame.origin.y)
                data.origin.x += shift;
                
                let left = CGFloat(data.origin.x)
                let right = left + CGFloat(data.size.x)
                
                let top = CGFloat(data.origin.y)
                let bottom = top + CGFloat(data.size.y)
                
                if bounds.contains(CGPoint(x: left, y: top)) ||
                    bounds.contains(CGPoint(x: right, y: top)) ||
                    bounds.contains(CGPoint(x: right, y: bottom)) ||
                    bounds.contains(CGPoint(x: left, y: bottom)) {
                    return data
                } else {
                    return nil
                }
            }
            let labelsRenderData = labelsRenderData.compactMap {
                var data = $0;
                data.0.origin.x += Float(frame.origin.x)
                data.0.origin.y += Float(frame.origin.y)
                data.0.origin.x += shift;
                
                let left = CGFloat(data.0.origin.x)
                let right = left + CGFloat(data.0.size.x)
                
                let top = CGFloat(data.0.origin.y)
                let bottom = top + CGFloat(data.0.size.y)
                
                if bounds.contains(CGPoint(x: left, y: top)) ||
                    bounds.contains(CGPoint(x: right, y: top)) ||
                    bounds.contains(CGPoint(x: right, y: bottom)) ||
                    bounds.contains(CGPoint(x: left, y: bottom)) {
                    return data
                } else {
                    return nil
                }
            }
            
            rects.append(contentsOf: rectsRenderData)
            labels.append(contentsOf: labelsRenderData)
        }
        
        result.0.append(contentsOf: rects)
        result.1.append(contentsOf: labels)
        subviewRenderDataCahce = result
        return result
    }
    
    // MARK: - Private
    
    private func stopOffsetAnimation() {
        contentOffsetAnimation?.invalidate()
        contentOffsetAnimation = nil
    }

    private func clampOffset(_ offset: CGPoint) -> CGPoint {
        let rubberBand = RubberBand(dims: bounds.size, bounds: contentOffsetBounds)
        return rubberBand.clamp(offset)
    }
    
    private func completeGesture(withVelocity velocity: CGPoint) {
        let target = project(value: offset, velocity: velocity, decelerationRate: decelerationRate)
        
        var startX: CGFloat = 0
        if case .dragging(let initialOffset) = state {
            startX = initialOffset.x
        }
        
        var horizontalShift = target.x - startX
        if horizontalShift < -pageScrollLimit {
            horizontalShift = -pageScrollLimit
        } else if horizontalShift > pageScrollLimit {
            horizontalShift = pageScrollLimit
        } else if !(-swipeThreshold...swipeThreshold).contains(horizontalShift) {
            horizontalShift = horizontalShift < 0 ? -1 : 1
        }
        
        let targetX = Int(startX + horizontalShift - 0.5)
        let xClamped = min(0, max(-subviews.count + 1, targetX))
        let restOffset = CGPoint(x: CGFloat(xClamped),
                                 y: CGFloat(Int(target.y)))
        
        let displacement = offset - restOffset
        let threshold: CGFloat = 0.5 / Settings.Camera.sceneHeight / 2
        
        let parameters = SpringTimingParameters(spring: .default,
                                                displacement: displacement,
                                                initialVelocity: velocity,
                                                threshold: threshold)
       
        contentOffsetAnimation = TimerAnimation(
            duration: parameters.duration,
            animations: { [weak self] _, time in
                self?.offset = restOffset + parameters.value(at: time)
            }, completion: { [weak self] _ in
                self?.stopOffsetAnimation()
            })
    }
    
    private func project(value: CGPoint, velocity: CGPoint, decelerationRate: CGFloat) -> CGPoint {
        return value - velocity / (1000 * log(decelerationRate))
    }
}
