//
//  LevelParser.swift
//  LevelParser
//
//  Created by Rost on 14.11.2022.
//

import UIKit

public final class LevelParser {
    
    public static func parse(_ image: UIImage) -> Level {
//        var result = [LevelChunk]()
//        guard let pixels = image.pixelData() else { fatalError() }
//        
//        let targetSize: CGFloat = 140
//        let scale = targetSize / max(image.size.width, image.size.height)
//        
//        for i in 0 ..< Int(image.size.height) {
//            for j in 0 ..< Int(image.size.width) {
//                let pixel = pixels[i * Int(image.size.height) + j]
//                guard let material = Material(color: pixel) else { continue }
//                
//                let x = j
//                let y = Int(image.size.height) - i
//                
//                var polygon = Polygon()
//                polygon.append(CGPoint(x: x, y: y))
//                polygon.append(CGPoint(x: x + 1, y: y))
//                polygon.append(CGPoint(x: x + 1, y: y + 1))
//                polygon.append(CGPoint(x: x, y: y + 1))
//
//                polygon = polygon.map {
//                    CGPoint(x: $0.x * scale, y: $0.y * scale)
//                }
//
//                let chunk = LevelChunk(polygon: polygon, material: material)
//                result.append(chunk)
//            }
//        }
//        
        return Level()
    }
}

extension UIImage {
    func pixelData() -> [UIColor]? {
        guard let cgImage = cgImage,
              let cfData = cgImage.dataProvider?.data,
              let buf = CFDataGetBytePtr(cfData)
        else { return nil }
        
        var result: [UIColor] = []
        let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
        for y in 0 ..< cgImage.height {
            for x in 0 ..< cgImage.width {
                let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
                
                result.append(UIColor(red: CGFloat(buf[offset]) / 255,
                                      green: CGFloat(buf[offset + 1]) / 255,
                                      blue: CGFloat(buf[offset + 2]) / 255,
                                      alpha: CGFloat(buf[offset + 3]) / 255))
            }
        }
        return result
    }
 }
