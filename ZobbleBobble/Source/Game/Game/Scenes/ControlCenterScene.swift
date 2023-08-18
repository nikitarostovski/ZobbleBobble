//
//  ControlCenterScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class ControlCenterScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .controlCenter }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Control center")
    private lazy var containerButton: GUIButton = GUIButton(title: "Container", tapAction: { [weak self] in self?.goTo(.containerSelection) })
    private lazy var improvementsButton: GUIButton = GUIButton(style: .secondary, title: "Improvements", tapAction: { [weak self] in self?.goTo(.improvements) })
    
    override func setupLayout() {
        gui = GUIBody(buttons: [containerButton, improvementsButton],
                      labels: [titleLabel],
                      backgroundColor: Colors.GUI.Background.light)
    }
    
    override func updateLayout() {
        let vp = Constants.paddingVertical / size.height
        let hp = Constants.paddingHorizontal / size.width
        
        let buttonWidth = safeArea.width - 2 * hp
        let buttonHeight = Constants.buttonHeight / size.height
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        
        let labelHeight = Constants.titleHeight / size.height
        
        titleLabel.frame = CGRect(x: safeArea.minX + hp,
                                  y: safeArea.minY + vp,
                                  width: safeArea.width - 2 * hp,
                                  height: labelHeight)
        containerButton.frame = CGRect(x: buttonX,
                                       y: safeArea.maxY - 2 * (buttonHeight + vp),
                                       width: buttonWidth,
                                       height: buttonHeight)
        improvementsButton.frame = CGRect(x: buttonX,
                                          y: safeArea.maxY - 4 * (buttonHeight + vp),
                                          width: buttonWidth,
                                          height: buttonHeight)
    }
}
