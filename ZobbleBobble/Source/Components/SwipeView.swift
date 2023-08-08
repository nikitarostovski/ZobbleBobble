//
//  SwipeView.swift
//  ZobbleBobble
//
//  Created by Rost on 01.01.2023.
//

import UIKit

protocol SwipeViewDelegate: AnyObject {
    func swipeViewDidSwipe(_ swipeView: SwipeView, totalOffset: CGPoint)
}

final class SwipeView: UIView, UIScrollViewDelegate {
    weak var delegate: SwipeViewDelegate?
    
    lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.delegate = self
        s.showsHorizontalScrollIndicator = false
        s.showsVerticalScrollIndicator = false
        s.isPagingEnabled = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    var maxSize: CGFloat = 0 {
        didSet {
            scrollView.contentSize.width = maxSize
        }
    }
    
    var pageSize: CGFloat = 0 {
        didSet {
            resetConstraints()
        }
    }
    
    var totalOffset: CGPoint = .zero {
        didSet {
            delegate?.swipeViewDidSwipe(self, totalOffset: totalOffset)
        }
    }
    
    init(delegate: SwipeViewDelegate?) {
        self.delegate = delegate
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        resetConstraints()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        totalOffset = scrollView.contentOffset
    }
    
    private func resetConstraints() {
        scrollView.removeFromSuperview()
        scrollView.removeConstraints(scrollView.constraints)
        
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: scrollView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: pageSize),
            NSLayoutConstraint(item: scrollView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        ])
        scrollView.contentSize.width = maxSize
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        scrollView.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        scrollView.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        scrollView.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        scrollView.touchesCancelled(touches, with: event)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return scrollView
    }
}
