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

    private var width = 32
    private var height = 64
    private var wallChance: Float = 0.48
    private var decompositionMode: PolygonDecompositionStrategy = .polygon
    
    var level = Level() {
        didSet {
            drawView.draw(level: level)
        }
    }
    
    @IBOutlet weak var widthTextField: NSTextField!
    @IBOutlet weak var heightTextField: NSTextField!
    @IBOutlet weak var wallChanceTextField: NSTextField!
    @IBOutlet weak var generateButton: NSButton!
    @IBOutlet weak var rectangleRadioButton: NSButton!
    @IBOutlet weak var polygonRadioButton: NSButton!
    
    @IBOutlet weak var drawView: DebugDrawView!
    
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
        
        let generatedData = MatrixGenerator.generate(width: width, height: height, unitCount: 3, wallChance: wallChance)
        let matrix = generatedData.0
        
        var polygons: [Polygon]
        switch decompositionMode {
        case .rectangle:
            polygons = PolygonConverter.makeRects(from: matrix, width: width, height: height)
        case .polygon:
            polygons = PolygonConverter.makePolygons(from: matrix, width: width, height: height)
        }
        
        polygons = polygons.map { $0.map { CGPoint(x: $0.x * CGFloat(width), y: $0.y * CGFloat(height)) } }
        
        self.level = Level(polygons: polygons)
    }
}
