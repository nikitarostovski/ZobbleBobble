//
//  BlackMarketScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

final class BlackMarketScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .blackMarket }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Black market")
    private lazy var backButton: GUIButton = GUIButton(style: .utility, title: "Back", tapAction: goToPlanetSelection)
    
    override func setupLayout() {
        gui = GUIBody(views: [titleLabel, backButton], backgroundColor: Colors.GUI.Background.light)
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
        
        backButton.frame = CGRect(x: buttonX,
                                  y: safeArea.maxY - buttonHeight - vp,
                                  width: buttonWidth,
                                  height: buttonHeight)
    }
}
