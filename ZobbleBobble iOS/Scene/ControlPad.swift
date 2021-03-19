//
//  ControlPad.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 15.02.2021.
//

import UIKit

final class ControlPad: UIView {
    
    private lazy var fireButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.backgroundColor = .blue
        button.addTarget(self, action: #selector(fireTap), for: .touchUpInside)
        button.setTitle("Fire", for: .normal)
        return button
    }()
    
    private lazy var restartButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.backgroundColor = .blue
        button.addTarget(self, action: #selector(resetTap), for: .touchUpInside)
        button.setTitle("Reset", for: .normal)
        return button
    }()
    
    var onFire: (() -> Void)?
    var onReset: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.red.withAlphaComponent(0.1)
        addSubview(fireButton)
        addSubview(restartButton)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        fireButton.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        restartButton.frame = CGRect(x: 120, y: 0, width: 100, height: 50)
    }
    
    @objc private func fireTap() {
        onFire?()
    }
    
    @objc private func resetTap() {
        onReset?()
    }
}
