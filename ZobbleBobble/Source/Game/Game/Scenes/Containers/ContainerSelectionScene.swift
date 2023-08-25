//
//  ContainerSelectionScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

final class ContainerSelectionScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .containerSelection }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Select a container") { [weak self] _ in
        guard let self = self else { return .zero }
        return CGRect(x: safeArea.minX + paddingHorizontal,
                      y: safeArea.minY + paddingVertical,
                      width: safeArea.width - 2 * paddingHorizontal,
                      height: titleHeight)
    }
    private lazy var utilizationPlantButton: GUIButton = GUIButton(style: .secondary, title: "Utilization plant", tapAction: goToUtilizationPlant) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        return CGRect(x: buttonX,
                      y: safeArea.minY + titleHeight + 2 * paddingVertical,
                      width: buttonWidth,
                      height: buttonHeight)
    }
    private lazy var garbageMarketButton: GUIButton = GUIButton(style: .secondary, title: "Garbage market", tapAction: goToGarbageMarket) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        return CGRect(x: buttonX,
                      y: safeArea.minY + titleHeight + 2 * paddingVertical + (buttonHeight + paddingVertical),
                      width: buttonWidth,
                      height: buttonHeight)
    }
    private lazy var containerButton: GUIButton = GUIButton(title: "Select", tapAction: goToPlanetSelection) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        return CGRect(x: buttonX,
                      y: safeArea.maxY - 2 * (buttonHeight + paddingVertical),
                      width: buttonWidth,
                      height: buttonHeight)
    }
    private lazy var backButton: GUIButton = GUIButton(style: .utility, title: "Back", tapAction: goToControlCenter) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        return CGRect(x: buttonX,
                      y: safeArea.maxY - buttonHeight - paddingVertical,
                      width: buttonWidth,
                      height: buttonHeight)
    }
    
    private lazy var containerCardViews: [GUIView] = {
        let containers = game?.player.containers ?? []
        
        return containers.enumerated().map { i, container in
            let view = GUIView()
            view.backgroundColor = .init(rgb: 0x00FF00, a: 100)
            view.onLayout = { [weak self] _ in
                guard let self = self else { return .zero }
                return CGRect(x: CGFloat(i) + paddingHorizontal,
                              y: paddingVertical,
                              width: 1 - 2 * paddingHorizontal,
                              height: scrollView.frame.height - 2 * paddingVertical)
            }
            
            let label = GUILabel(text: "Container \(i + 1)")
            label.backgroundColor = .init(rgb: 0xFFFFFF, a: 100)
            label.onLayout = { [weak self, weak view] _ in
                guard let self = self, let view = view else { return .zero }
                return CGRect(x: paddingHorizontal,
                              y: paddingVertical,
                              width: view.frame.width - 2 * paddingHorizontal,
                              height: titleHeight)
            }
            view.subviews.append(label)
            
            return view
        }
    }()
    
    private lazy var scrollView: GUIScrollView = {
        let view = GUIScrollView(subviews: containerCardViews)
        view.contentSize.width = CGFloat(view.subviews.count)
        view.backgroundColor = .init(rgb: 0xFF0000, a: 100)
        let scale = size.height / (Settings.Camera.sceneHeight * Settings.Graphics.resolutionDownscale)
        
        view.onLayout = { [weak self] _ in
            guard let self = self else { return .zero }
            let top = garbageMarketButton.frame.maxY + paddingVertical
            let bottom = containerButton.frame.minY - paddingVertical
            let height =  bottom - top
            return CGRect(x: 0, y: top, width: 1, height: height)
        }
        view.onScroll = { [weak self] view in
            guard let self = self else { return }
            
            let containerIndex = Int(view.contentOffset.x + 0.5)
            if selectedContainerIndex != containerIndex {
                selectedContainerIndex = containerIndex
                game?.selectContainer(containerIndex)
            }
            
            updateContainerFrames()
        }
        return view
    }()
    
    private lazy var containerBackgroundView: GUIView = {
        let view = GUIView()
        view.backgroundColor = .init(rgb: 0x0000FF, a: 63)
        view.onLayout = { [weak self] view in
            guard let self = self else { return .zero }
            
            let height = scrollView.frame.height - titleHeight - 3 * paddingVertical
            let width = height / size.width * size.height
            
            let x = (size.width / 2 - scrollView.contentOffset.x) / size.width - width / 2
            let y = scrollView.frame.maxY - height - paddingVertical
            
            return CGRect(x: x, y: y, width: width, height: height)
        }
        return view
    }()
    
    private lazy var selectedContainerIndex: Int = {
        return game?.player.selectedContainerIndex ?? 0
    }()
    
    private var containerBodies = [ContainerBody]()
    
    override var visibleBodies: [any Body] {
        var visibleBodies = [any Body]()
        if let gui = gui {
            visibleBodies.append(gui)
        }
        visibleBodies.append(contentsOf: containerBodies)
        return visibleBodies
    }
    
    override func setupLayout() {
        gui = GUIBody(views: [titleLabel, scrollView, containerBackgroundView, backButton, utilizationPlantButton, garbageMarketButton, containerButton])
        
        (game?.player.selectedContainerIndex).map {
            self.selectedContainerIndex = $0
            self.scrollView.contentOffset.x = CGFloat($0)
        }
        
        containerBodies = game?.player.containers.map {
            ContainerBody(container: $0, frame: .zero)
        } ?? []
    }
    
    override func updateLayout() {
        super.updateLayout()
        updateContainerFrames()
    }
    
    private func updateContainerFrames() {
        let gameTextureHeight = Settings.Camera.sceneHeight * Settings.Graphics.resolutionDownscale
        let scale = size.height / gameTextureHeight
        let height = containerBackgroundView.frame.height * 0.8 * gameTextureHeight
        let width = height / ContainerBody.aspectRatio
        
        containerBodies.enumerated().forEach { i, containerBody in
            let x = (CGFloat(i) - self.scrollView.contentOffset.x) / scale * self.size.width
            let y = Settings.Camera.sceneHeight * (self.containerBackgroundView.frame.midY - 0.5)
            
            containerBody.center = CGPoint(x: x, y: y)
            containerBody.size = CGSize(width: width, height: height)
        }
    }
}
