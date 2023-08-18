//
//  GameResultsScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class GameResultsScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .gameResults }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Game Results")
    private lazy var controlCenterButton: GUIButton = GUIButton(title: "Control Center", tapAction: { [weak self] in self?.goTo(.controlCenter) })
    private lazy var improvementsButton: GUIButton = GUIButton(style: .secondary, title: "Improvements", tapAction: { [weak self] in self?.goTo(.improvements) })
    
    override func setupLayout() {
        gui = GUIBody(buttons: [controlCenterButton, improvementsButton],
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
