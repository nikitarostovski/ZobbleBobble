//
//  PlanetSelectionScene.swift
//  ZobbleBobble
//
//  Created by Rost on 17.08.2023.
//

import Foundation
import Levels

struct PlanetSelectionState {
    /// progress from level state to menuPacks state [1...3] (1 is level state, 2 is level selection, 3 is pack selection)
    var levelToPackProgress: CGFloat
    /// horizontal scroll position of level in index values (1.5 equals exact middle between indices 1 and 2)
    var currentLevelPagePosition: CGFloat
    /// horizontal scroll position of pack in index values (1.5 equals exact middle between indices 1 and 2)
    var currentPackPagePosition: CGFloat
}

final class PlanetSelectionScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .planetSelection }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Planet selection")
    private lazy var blackMarketButton: GUIButton = GUIButton(style: .secondary, title: "Black market", tapAction: goToBlackMarket)
    private lazy var planetButton: GUIButton = GUIButton(title: "To Planet", tapAction: goToPlanet)
    private lazy var backButton: GUIButton = GUIButton(style: .utility, title: "Back", tapAction: goToContainerSelection)
    
    
    private var starCenterLevelMode: CGPoint = .zero
    private var starCenterMenuLevelMode: CGPoint = .zero
    private var starCenterMenuPackMode: CGPoint = .zero

    private var planetCenterLevelMode: CGPoint = .zero
    private var planetCenterMenuLevelMode: CGPoint = .zero
    private var planetCenterMenuPackMode: CGPoint = .zero

    private var starRadiusScale: CGFloat = 0
    private var planetRadiusScale: CGFloat = 0

    private var starCenterPoint: CGPoint = .zero
    private var planetCenterPoint: CGPoint = .zero

    private var starAngleBetweenPositions: CGFloat = 0
    private var planetAngleBetweenPositions: CGFloat = 0

    private var starRadius: CGFloat = 0
    private var starAnchor: CGPoint = .zero

    private var planetRadius: CGFloat = 0
    private var planetAnchor: CGPoint = .zero

    private var starCenterAngle: CGFloat = 0
    private var planetCenterAngle: CGFloat = 0
    
    private var lastUpdateGameSize: CGSize = .zero
    private var lastUpdateLevelToPackProgress: CGFloat = -1
    private var lastUpdateCurrentPackPagePosition: CGFloat = -1
    private var lastUpdateCurrentLevelPagePosition: CGFloat = -1

    private(set) var visibleLevelIndices: ClosedRange<Int> = 0...0

//    private(set) var state: PlanetSelectionState
    
    private weak var terrainBody: TerrainBody?
    
    private let levelManager: LevelManager

//    private var visibleLevels: [LevelModel] {
//        Array(currentPack!.levels[visibleLevelIndices])
//    }
    
    init?(currentVisibility: Float = 1,
          size: CGSize,
          safeArea: CGRect,
          screenScale: CGFloat,
          from: CGFloat = Settings.Camera.levelsMenuCameraScale,
          to: CGFloat = Settings.Camera.levelsMenuCameraScale) {
        
        if let levelDataPath = Bundle(for: LevelManager.self).path(forResource: "/Data/Levels", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: levelDataPath), options: .mappedIfSafe)
                levelManager = try LevelManager(levelData: data)
            } catch {
                return nil
            }
        } else {
            return nil
        }
        
        super.init(currentVisibility: currentVisibility, size: size, safeArea: safeArea, screenScale: screenScale)
        
//        self.state = PlanetSelectionState(levelToPackProgress: from, currentLevelPagePosition: 0, currentPackPagePosition: 0)
//
//        self.stars = levelManager.allLevelPacks.map { pack in
//            StarBody(pack: pack)
//        }
//
//        let terrainBody = TerrainBody(physicsWorld: nil, uniqueMaterials: Array(Set(visibleLevels.flatMap { $0.allMaterials })))
//        self.terrainBody = terrainBody
//
//        if (to == from) {
//            updateScroll()
//            updateRenderData()
//            return
//        }
//        switch to {
//        case Settings.Camera.levelCameraScale:
//            transitionToLevel()
//        case Settings.Camera.levelsMenuCameraScale:
//            transitionToLevelSelection()
//        case Settings.Camera.packsMenuCameraScale:
//            transitionToPackSelection()
//        default:
//            break
//        }
    }
    
    private func goToPlanet() {
        guard let pack = levelManager.allLevelPacks.first, let level = pack.levels.first else { return }
        
        let containers: [ContainerModel] = pack.levels.map { .init(missles: $0.missleChunks) }
        
        var player = PlayerModel(containers: containers)
        player.selectedContainerIndex = 0
        
        let planet = PlanetModel(speed: level.rotationPerSecond,
                                 chunks: level.initialChunks,
                                 gravityRadius: level.gravityRadius,
                                 gravitySthrength: 1,
                                 particleRadius: pack.particleRadius)
        goToPlanet(planet, player: player)
    }
    
    override func setupLayout() {
        gui = GUIBody(buttons: [blackMarketButton, planetButton, backButton],
                      labels: [titleLabel],
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

//extension PlanetSelectionScene {
//    private func convertStarPosition(_ index: Int) -> CGPoint? {
//        var distToCenter: CGFloat = 0
//        if state.levelToPackProgress > 2 {
//            distToCenter = CGFloat(index) - state.currentPackPagePosition
//        } else {
//            distToCenter = CGFloat(index) - CGFloat(game!.state.packIndex)
//        }
//        let targetAngle = starCenterAngle + distToCenter * starAngleBetweenPositions
//        let x = starAnchor.x - starRadius * cos(targetAngle)
//        let y = starAnchor.y - starRadius * sin(targetAngle)
//        return CGPoint(x: x, y: y)
//    }
//
//    private func convertStarRadius(_ radius: CGFloat) -> CGFloat? {
//        radius * starRadiusScale
//    }
//
//    private func convertPlanetPosition(_ index: Int) -> CGPoint? {
//        var distToCenter: CGFloat = 0
//        if state.levelToPackProgress > 1, state.levelToPackProgress < 3 {
//            distToCenter = CGFloat(index) - state.currentLevelPagePosition
//        }
//        let targetAngle = planetCenterAngle + distToCenter * planetAngleBetweenPositions
//        let x = planetAnchor.x - planetRadius * cos(targetAngle)
//        let y = planetAnchor.y - planetRadius * sin(targetAngle)
//        return CGPoint(x: x, y: y)
//    }
//
//    private func convertPlanetRadius(_ radius: CGFloat) -> CGFloat? {
//        radius * planetRadiusScale
//    }
//
//    private func convertPlanetChunkPosition(_ levelIndex: Int, position: CGPoint) -> CGPoint {
//        let levelPosition = convertPlanetPosition(levelIndex) ?? .zero
//        return CGPoint(x: levelPosition.x + position.x * planetRadiusScale, y: levelPosition.y + position.y * planetRadiusScale)
//    }
//}
