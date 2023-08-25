//
//  PlanetSelectionScene.swift
//  ZobbleBobble
//
//  Created by Rost on 17.08.2023.
//

import Foundation

final class PlanetSelectionScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .planetSelection }
    
    private let maxPlanetScale: CGFloat = 3
    
    private lazy var selectedPlanetIndex: Int = {
        return game?.player.selectedPlanetIndex ?? 0
    }()
    
    private var planetBodies = [StaticTerrainBody]()
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Select a planet") { [weak self] _ in
        guard let self = self else { return .zero }
        return CGRect(x: safeArea.minX + paddingHorizontal,
                      y: safeArea.minY + paddingVertical,
                      width: safeArea.width - 2 * paddingHorizontal,
                      height: titleHeight)
    }
    
    private lazy var blackMarketButton: GUIButton = GUIButton(style: .secondary, title: "Black market", tapAction: goToBlackMarket) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        
        return CGRect(x: buttonX,
                      y: safeArea.minY + titleHeight + 2 * paddingVertical,
                      width: buttonWidth,
                      height: buttonHeight)
    }
    
    private lazy var planetButton: GUIButton = GUIButton(title: "Select", tapAction: goToPlanet) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        
        return CGRect(x: buttonX,
                      y: safeArea.maxY - 2 * (buttonHeight + paddingVertical),
                      width: buttonWidth,
                      height: buttonHeight)
    }
    
    private lazy var backButton: GUIButton = GUIButton(style: .utility, title: "Back", tapAction: goToContainerSelection) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        
        return CGRect(x: buttonX,
                      y: safeArea.maxY - buttonHeight - paddingVertical,
                      width: buttonWidth,
                      height: buttonHeight)
    }
    
    private lazy var planetCardViews: [GUIView] = {
        let planets = game?.player.planets ?? []
        
        return planets.enumerated().map { i, planet in
            let container = GUIView()
            container.backgroundColor = .init(rgb: 0x00FF00, a: 100)
            container.onLayout = { [weak self] _ in
                guard let self = self else { return .zero }
                return CGRect(x: CGFloat(i) + paddingHorizontal,
                              y: paddingVertical,
                              width: 1 - 2 * paddingHorizontal,
                              height: scrollView.frame.height - 2 * paddingVertical)
            }
            
            let label = GUILabel(text: planet.name)
            label.backgroundColor = .init(rgb: 0xFFFFFF, a: 100)
            label.onLayout = { [weak self, weak container] _ in
                guard let self = self, let container = container else { return .zero }
                return CGRect(x: paddingHorizontal,
                              y: paddingVertical,
                              width: container.frame.width - 2 * paddingHorizontal,
                              height: titleHeight)
            }
            container.subviews.append(label)
            
            return container
        }
    }()
    
    private lazy var scrollView: GUIScrollView = {
        let view = GUIScrollView(subviews: planetCardViews)
        view.contentSize.width = CGFloat(view.subviews.count)
        view.backgroundColor = .init(rgb: 0xFF0000, a: 100)
        let scale = size.height / (Settings.Camera.sceneHeight * Settings.Graphics.resolutionDownscale)
        
        view.onLayout = { [weak self] _ in
            guard let self = self else { return .zero }
            let top = blackMarketButton.frame.maxY + paddingVertical
            let bottom = planetButton.frame.minY - paddingVertical
            let height =  bottom - top
            return CGRect(x: 0, y: top, width: 1, height: height)
        }
        view.onScroll = { [weak self] view in
            guard let self = self else { return }
            
            let planetIndex = Int(view.contentOffset.x + 0.5)
            if selectedPlanetIndex != planetIndex {
                selectedPlanetIndex = planetIndex
                game?.selectPlanet(planetIndex)
            }
            
            planetBodies.enumerated().forEach { i, planetBody in
                planetBody.offset.x = (CGFloat(i) - view.contentOffset.x) / scale * self.size.width
                planetBody.offset.y = Settings.Camera.sceneHeight * (self.planetBackgroundView.frame.midY - 0.5)
            }
        }
        return view
    }()
    
    private lazy var planetBackgroundView: GUIView = {
        let view = GUIView()
        view.backgroundColor = .init(rgb: 0x0000FF, a: 63)
        let gameTextureHeight = Settings.Camera.sceneHeight * Settings.Graphics.resolutionDownscale
        let scale = size.height / gameTextureHeight
        
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
    
    private var planetVisibilityRadius: CGFloat {
        // by furthest chunk
        game?.player.selectedPlanet?.chunks.map { $0.boundingRadius }.max() ?? 1
        // by gravity radius
//        planet.gravityRadius
    }
    
    override var visibleBodies: [any Body] {
        var visibleBodies = [any Body]()
        if let gui = gui {
            visibleBodies.append(gui)
        }
        visibleBodies.append(contentsOf: planetBodies)
        return visibleBodies
    }
    
    override func setupLayout() {
        gui = GUIBody(views: [titleLabel, scrollView, blackMarketButton, planetButton, backButton, planetBackgroundView])
        
        (game?.player.selectedPlanetIndex).map {
            self.selectedPlanetIndex = $0
            self.scrollView.contentOffset.x = CGFloat($0)
        }
        
        planetBodies = game?.player.planets.map {
            StaticTerrainBody(chunks: $0.chunks)
        } ?? []
    }
    
    override func updateLayout() {
        super.updateLayout()
        
        let guiHeight = planetBackgroundView.frame.height
        let gameHeight = (2 * planetVisibilityRadius) / Settings.Camera.sceneHeight
        
        let scale = min(maxPlanetScale, guiHeight / gameHeight)
        
        planetBodies.forEach { $0.scale = scale }
    }
}
