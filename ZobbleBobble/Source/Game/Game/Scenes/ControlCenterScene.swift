//
//  ControlCenterScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

final class ControlCenterScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .controlCenter }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Control center") { [weak self] _ in
        guard let self = self else { return .zero }
        return CGRect(x: safeArea.minX + paddingHorizontal,
                      y: safeArea.minY + paddingVertical,
                      width: safeArea.width - 2 * paddingHorizontal,
                      height: titleHeight)
    }
    
    private lazy var creditsLabel: GUILabel = GUILabel(style: .info) { [weak self] _ in
        guard let self = self else { return .zero }
        creditsLabel.text = game.map { "$ \($0.player.credits)" }
        return CGRect(x: safeArea.minX + paddingHorizontal,
                      y: safeArea.minY + 2 * paddingVertical + titleHeight,
                      width: safeArea.width - 2 * paddingHorizontal,
                      height: titleHeight)
    }
    
    private lazy var containerButton: GUIButton = GUIButton(title: "Container", tapAction: goToContainerSelection) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        return CGRect(x: buttonX,
                      y: safeArea.maxY - 2 * (buttonHeight + paddingVertical),
                      width: buttonWidth,
                      height: buttonHeight)
    }
    
    private lazy var improvementsButton: GUIButton = GUIButton(style: .secondary, title: "Improvements", tapAction: goToImprovements) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        return CGRect(x: buttonX,
                      y: safeArea.maxY - 4 * (buttonHeight + paddingVertical),
                      width: buttonWidth,
                      height: buttonHeight)
    }
    
    override func setupLayout() {
        gui = GUIBody(views: [titleLabel, creditsLabel, containerButton, improvementsButton],
                      backgroundColor: Colors.GUI.Background.light)
    }
}
