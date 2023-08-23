//
//  ContainerSelectionScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

final class ContainerSelectionScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .containerSelection }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Container selection")
    private lazy var utilizationPlantButton: GUIButton = GUIButton(style: .secondary, title: "Utilization plant", tapAction: goToUtilizationPlant)
    private lazy var garbageMarketButton: GUIButton = GUIButton(style: .secondary, title: "Garbage market", tapAction: goToGarbageMarket)
    private lazy var planetSelectionButton: GUIButton = GUIButton(title: "Planet selection", tapAction: goToPlanetSelection)
    private lazy var backButton: GUIButton = GUIButton(style: .utility, title: "Back", tapAction: goToControlCenter)
    
    override func setupLayout() {
        gui = GUIBody(views: [titleLabel, backButton, utilizationPlantButton, garbageMarketButton, planetSelectionButton],
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
        
        utilizationPlantButton.frame = CGRect(x: buttonX,
                                       y: safeArea.maxY - 5 * (buttonHeight + vp),
                                       width: buttonWidth,
                                       height: buttonHeight)
        
        garbageMarketButton.frame = CGRect(x: buttonX,
                                       y: safeArea.maxY - 4 * (buttonHeight + vp),
                                       width: buttonWidth,
                                       height: buttonHeight)
        
        planetSelectionButton.frame = CGRect(x: buttonX,
                                       y: safeArea.maxY - 2 * (buttonHeight + vp),
                                       width: buttonWidth,
                                       height: buttonHeight)
        
        backButton.frame = CGRect(x: buttonX,
                                  y: safeArea.maxY - buttonHeight - vp,
                                  width: buttonWidth,
                                  height: buttonHeight)
    }
}
