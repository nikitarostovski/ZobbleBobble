//
//  WeaponPickerView.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 19.01.2022.
//

import UIKit

protocol WeaponPickerDelegate: AnyObject {
    func weaponPickerDidChange(weapon: WeaponType)
}

final class WeaponPickerView: UIView {
    weak var delegate: WeaponPickerDelegate?
    
    var weapons: [WeaponType] = [] {
        didSet {
            resetContent()
        }
    }
    
    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.backgroundColor = .cyan
        s.translatesAutoresizingMaskIntoConstraints = false
        s.showsHorizontalScrollIndicator = false
        return s
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        scrollView.frame = bounds
        addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        ])
        
        resetContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func resetContent() {
        let buttonSize = scrollView.bounds.height
        let inset: CGFloat = 12
        var lastView: UIView?
        for (i, weapon) in weapons.enumerated() {
            let x = CGFloat(i) * (buttonSize + inset)
            let button = WeaponButton(frame: CGRect(x: inset + x, y: 0, width: buttonSize, height: buttonSize))
            button.addTarget(self, action: #selector(weaponTap(_:)), for: .touchUpInside)
            button.setTitle(weapon.rawValue, for: .normal)
            button.weaponIndex = i
            button.backgroundColor = .red
            scrollView.addSubview(button)
            lastView = button
        }
        scrollView.contentSize.width = lastView?.frame.maxX ?? 0 + inset
    }
    
    @objc
    private func weaponTap(_ sender: WeaponButton) {
        guard let index = sender.weaponIndex else { return }
        delegate?.weaponPickerDidChange(weapon: weapons[index])
    }
}
