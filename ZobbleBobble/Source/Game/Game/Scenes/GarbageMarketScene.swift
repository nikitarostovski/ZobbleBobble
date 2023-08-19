//
//  GarbageMarketScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class GarbageMarketScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .garbageMarket }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Garbage market")
    private lazy var backButton: GUIButton = GUIButton(style: .utility, title: "Back", tapAction: goToContainerSelection)
    
    override func setupLayout() {
        gui = GUIBody(buttons: [backButton],
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
        
        backButton.frame = CGRect(x: buttonX,
                                  y: safeArea.maxY - buttonHeight - vp,
                                  width: buttonWidth,
                                  height: buttonHeight)
    }
}
