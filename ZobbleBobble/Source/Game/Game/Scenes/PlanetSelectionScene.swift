//
//  PlanetSelectionScene.swift
//  ZobbleBobble
//
//  Created by Rost on 17.08.2023.
//

import Foundation
import Levels

final class PlanetSelectionScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .planetSelection }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Planet selection")
    private lazy var blackMarketButton: GUIButton = GUIButton(style: .secondary, title: "Black market", tapAction: { [weak self] in self?.goTo(.blackMarket) })
    private lazy var planetButton: GUIButton = GUIButton(title: "To Planet", tapAction: { [weak self] in self?.goTo(.planet) })
    private lazy var backButton: GUIButton = GUIButton(style: .utility, title: "Back", tapAction: { [weak self] in self?.goTo(.containerSelection) })
    
    override func setupLayout() {
        gui = GUIBody(buttons: [blackMarketButton, planetButton, backButton],
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
        
        blackMarketButton.frame = CGRect(x: buttonX,
                                         y: safeArea.maxY - 4 * (buttonHeight + vp),
                                         width: buttonWidth,
                                         height: buttonHeight)
        
        planetButton.frame = CGRect(x: buttonX,
                                    y: safeArea.maxY - 2 * (buttonHeight + vp),
                                    width: buttonWidth,
                                    height: buttonHeight)
        
        backButton.frame = CGRect(x: buttonX,
                                  y: safeArea.maxY - buttonHeight - vp,
                                  width: buttonWidth,
                                  height: buttonHeight)
    }
}
