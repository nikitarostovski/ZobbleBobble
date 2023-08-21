//
//  GameResultsScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

final class GameResultsScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .gameResults }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Game Results")
    private lazy var controlCenterButton: GUIButton = GUIButton(title: "Control Center", tapAction: goToControlCenter)
    private lazy var improvementsButton: GUIButton = GUIButton(style: .secondary, title: "Improvements", tapAction: goToImprovements)
    
    override func setupLayout() {
        gui = GUIBody(buttons: [controlCenterButton, improvementsButton],
                      labels: [titleLabel],
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
        
        controlCenterButton.frame = CGRect(x: buttonX,
                                       y: safeArea.maxY - 2 * buttonHeight - 2 * vp,
                                       width: buttonWidth,
                                       height: buttonHeight)
        
        improvementsButton.frame = CGRect(x: buttonX,
                                          y: safeArea.maxY - buttonHeight - vp,
                                          width: buttonWidth,
                                          height: buttonHeight)
    }
}
