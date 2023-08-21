//
//  ControlCenterScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

final class ControlCenterScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .controlCenter }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Control center")
    private lazy var creditsLabel: GUILabel = GUILabel(style: .info)
    private lazy var containerButton: GUIButton = GUIButton(title: "Container", tapAction: goToContainerSelection)
    private lazy var improvementsButton: GUIButton = GUIButton(style: .secondary, title: "Improvements", tapAction: goToImprovements)
    
    override func setupLayout() {
        gui = GUIBody(views: [titleLabel, creditsLabel, containerButton, improvementsButton],
                      backgroundColor: Colors.GUI.Background.light)
    }
    
    override func updateLayout() {
        let vp = paddingVertical
        let hp = paddingHorizontal
        
        let buttonWidth = safeArea.width - 2 * hp
        let buttonHeight = buttonHeight
        
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        
        let labelHeight = titleHeight
        
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
        
        creditsLabel.frame = CGRect(x: safeArea.minX + hp,
                                    y: safeArea.minY + 2 * vp + labelHeight,
                                    width: safeArea.width - 2 * hp,
                                    height: labelHeight)
        
        creditsLabel.text = game.map { "$ \($0.player.credits)" }
    }
}
