//
//  GUIScrollView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.08.2023.
//

import Foundation

class GUIScrollView: GUIView {
    private var startPoint: CGPoint?
    private var startShift: CGPoint?
    private var currentShift: CGPoint = .zero
    
    override func onTouchDown(pos: CGPoint) -> Bool {
        startPoint = pos
        startShift = currentShift
        return true
    }
    
    override func onTouchMove(pos: CGPoint) -> Bool {
        guard let startPoint = startPoint else { return false }
        currentShift = CGPoint(x: (startShift?.x ?? 0) + pos.x - startPoint.x,
                               y: (startShift?.y ?? 0) + pos.y - startPoint.y)
        return true
    }
    
    override func onTouchUp(pos: CGPoint) -> Bool {
        startPoint = nil
        startShift = .zero
        return true
    }

    override func makeSubviewsRenderData() -> RenderData {
        var result = RenderData([], [])
        defer { needsDisplay = false }
        
        var rects = [GUIRenderData.RectModel]()
        var labels = [(GUIRenderData.LabelModel, GUIRenderData.TextRenderData)]()
        
        let allRenderData = subviews.map { $0.makeRenderData() }
        
        allRenderData.forEach { rectsRenderData, labelsRenderData in
            let shift = Float(self.currentShift.x)
            let rectsRenderData = rectsRenderData.map {
                var data = $0;
                data.origin.x += Float(frame.origin.x)
                data.origin.y += Float(frame.origin.y)
                data.origin.x += shift;
                return data;
            }
            let labelsRenderData = labelsRenderData.map {
                var data = $0;
                data.0.origin.x += Float(frame.origin.x)
                data.0.origin.y += Float(frame.origin.y)
                data.0.origin.x += shift;
                return data;
            }
            
            rects.append(contentsOf: rectsRenderData)
            labels.append(contentsOf: labelsRenderData)
        }
        
        result.0.append(contentsOf: rects)
        result.1.append(contentsOf: labels)
        return result
    }
}
