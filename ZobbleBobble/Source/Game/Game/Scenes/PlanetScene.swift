//
//  PlanetScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class PlanetScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .planet }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Planet")
    private lazy var controlCenterButton: GUIButton = GUIButton(style: .secondary, title: "Control center", tapAction: { [weak self] in self?.goTo(.controlCenter) })
    private lazy var resultsButton: GUIButton = GUIButton(title: "Game results", tapAction: { [weak self] in self?.goTo(.gameResults) })
    
    override func setupLayout() {
        gui = GUIBody(buttons: [controlCenterButton, resultsButton],
                      labels: [titleLabel],
                      backgroundColor: Colors.GUI.Background.dark)
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
        
        resultsButton.frame = CGRect(x: buttonX,
                                     y: safeArea.maxY - 2 * (buttonHeight + vp),
                                     width: buttonWidth,
                                     height: buttonHeight)
        
        controlCenterButton.frame = CGRect(x: buttonX,
                                           y: safeArea.maxY - 3 * (buttonHeight + vp),
                                           width: buttonWidth,
                                           height: buttonHeight)
    }
}
