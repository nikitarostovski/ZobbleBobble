//
//  ContainerSelectionScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class ContainerSelectionScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .containerSelection }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Container selection")
    private lazy var utilizationPlantButton: GUIButton = GUIButton(style: .secondary, title: "Utilization plant", tapAction: { [weak self] in self?.goTo(.utilizationPlant) })
    private lazy var garbageMarketButton: GUIButton = GUIButton(style: .secondary, title: "Garbage market", tapAction: { [weak self] in self?.goTo(.garbageMarket) })
    private lazy var planetSelectionButton: GUIButton = GUIButton(title: "Planet selection", tapAction: { [weak self] in self?.goTo(.planetSelection) })
    private lazy var backButton: GUIButton = GUIButton(style: .utility, title: "Back", tapAction: { [weak self] in self?.goTo(.controlCenter) })
    
    override func setupLayout() {
        gui = GUIBody(buttons: [backButton, utilizationPlantButton, garbageMarketButton, planetSelectionButton],
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
