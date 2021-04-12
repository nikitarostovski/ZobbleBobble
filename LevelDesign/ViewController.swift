//
//  ViewController.swift
//  LevelDesign
//
//  Created by Rost on 17.03.2021.
//

import Cocoa

class ViewController: NSViewController {
    
    enum PolygonDecompositionStrategy {
        case rectangle
        case polygon
    }
    
    enum SelectionMode {
        case none
        case player
        case exit
        case checkpoint
    }

    private var width = 48
    private var height = 48
    private var wallChance: Float = 0.48
    private var decompositionMode: PolygonDecompositionStrategy = .rectangle
    
    var level = Level(width: 0, height: 0) {
        didSet {
            drawView.draw(level: level)
        }
    }
    
    var selectionMode: SelectionMode = .none {
        didSet {
            itemPlayerButton.state = .off
            itemExitButton.state = .off
            itemCheckpointButton.state = .off
            
            switch selectionMode {
            case .exit: itemExitButton.state = .on
            case .player: itemPlayerButton.state = .on
            case .checkpoint: itemCheckpointButton.state = .on
            default: break
            }
        }
    }
    
    @IBOutlet weak var widthTextField: NSTextField!
    @IBOutlet weak var heightTextField: NSTextField!
    @IBOutlet weak var wallChanceTextField: NSTextField!
    @IBOutlet weak var generateButton: NSButton!
    @IBOutlet weak var rectangleRadioButton: NSButton!
    @IBOutlet weak var polygonRadioButton: NSButton!
    
    @IBOutlet weak var itemPlayerButton: NSButton!
    @IBOutlet weak var itemExitButton: NSButton!
    @IBOutlet weak var itemCheckpointButton: NSButton!
    
    @IBOutlet weak var saveButton: NSButton!
    
    @IBOutlet weak var drawView: DebugDrawView! {
        didSet {
            drawView.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        widthTextField.stringValue = "\(width)"
        heightTextField.stringValue = "\(height)"
        wallChanceTextField.stringValue = "\(Int(wallChance * 100))"
        rectangleRadioButton.state = decompositionMode == .rectangle ? .on : .off
        polygonRadioButton.state = decompositionMode == .polygon ? .on : .off
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func saveTap(_ sender: Any) {
        let homePath = FileManager.default.homeDirectoryForCurrentUser
        let desktopPath = homePath.appendingPathComponent("Desktop/ZobbleBobble/ZobbleBobble iOS/Resource")
        let filePath = desktopPath.appendingPathComponent("Level.lvl")
        
        guard let unicodeString = level.save() else { print("Can not make json"); return }
        
        do {
            try unicodeString.write(to: filePath, atomically: false, encoding: .utf8)
        } catch {
            print("Can not write file")
        }
    }
    
    @IBAction func itemPlayerTap(_ sender: Any) {
        if selectionMode == .player {
            selectionMode = .none
        } else {
            selectionMode = .player
        }
    }
    
    @IBAction func itemExitTap(_ sender: Any) {
        if selectionMode == .exit {
            selectionMode = .none
        } else {
            selectionMode = .exit
        }
    }
    
    @IBAction func itemCheckpointTap(_ sender: Any) {
        if selectionMode == .checkpoint {
            selectionMode = .none
        } else {
            selectionMode = .checkpoint
        }
    }
    
    @IBAction func rectModeSelect(_ sender: Any) {
        polygonRadioButton.state = .off
    }
    
    @IBAction func polygonModeSelect(_ sender: Any) {
        rectangleRadioButton.state = .off
    }
    
    @IBAction func generateTap(_ sender: Any) {
        width = Int(widthTextField.stringValue) ?? 0
        height = Int(heightTextField.stringValue) ?? 0
        wallChance = Float(Int(wallChanceTextField.stringValue) ?? 0) / 100.0
        if rectangleRadioButton.state == .on {
            decompositionMode = .rectangle
        } else if polygonRadioButton.state == .on {
            decompositionMode = .polygon
        }
        
//        let generatedData = MatrixGenerator.generate(width: width, height: height, unitCount: 3, wallChance: wallChance)
//        let matrix = generatedData.0
        
        var polygons: [Polygon]
//        switch decompositionMode {
//        case .rectangle:
//            polygons = PolygonConverter.makeRects(from: matrix, width: width, height: height)
//        case .polygon:
//            polygons = PolygonConverter.makePolygons(from: matrix, width: width, height: height)
//        }
        
        polygons = MapGenerator.make(width: width, height: height, unitCount: 3, wallChance: wallChance)
        
//        polygons = polygons.map { $0.map { CGPoint(x: $0.x * CGFloat(width), y: $0.y * CGFloat(height)) } }
        
        self.level = Level(width: CGFloat(width), height: CGFloat(height), polygons: polygons)
    }
}


extension ViewController: DebugDrawViewInteractionDelegate {
    
    func didTap(at point: CGPoint) {
        let convertedPoint = CGPoint(x: point.x * CGFloat(width),
                                     y: point.y * CGFloat(height))
        switch selectionMode {
        case .none:
            break
        case .player:
            if level.playerPosition == nil {
                level.playerPosition = convertedPoint
            } else {
                level.playerPosition = nil
            }
        case .exit:
            if level.exitPosition == nil {
                level.exitPosition = convertedPoint
            } else {
                level.exitPosition = nil
            }
        case .checkpoint:
            level.checkpoints.append(convertedPoint)
        }
        drawView.update()
    }
}
