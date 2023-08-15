//
//  CGImage+Textures.swift
//  ZobbleBobble
//
//  Created by Rost on 14.08.2023.
//

import CoreGraphics
import MetalKit

public extension CGImage {
    static func bitmapInfo() -> CGBitmapInfo {
        
        // let noAlpha = CGImageAlphaInfo.noneSkipLast.rawValue
        let alpha = CGImageAlphaInfo.premultipliedLast.rawValue
        let bigEn32 = CGBitmapInfo.byteOrder32Big.rawValue
    
        // return CGBitmapInfo(rawValue: noAlpha | bigEn32)
        return CGBitmapInfo(rawValue: alpha | bigEn32)
    }
    
    static func dataProvider(data: UnsafeMutableRawPointer, size: CGSize) -> CGDataProvider? {
        
        let dealloc: CGDataProviderReleaseDataCallback = {
            
            (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> Void in
            
            // Core Foundation objects are memory managed, aren't they?
            return
        }
        
        return CGDataProvider(dataInfo: nil,
                              data: data,
                              size: 4 * Int(size.width) * Int(size.height),
                              releaseData: dealloc)
    }
    
    // Creates a CGImage from a raw data stream in 32 bit big endian format
    static func make(data: UnsafeMutableRawPointer, size: CGSize) -> CGImage? {
        
        let w = Int(size.width)
        let h = Int(size.height)
        
        return CGImage(width: w, height: h,
                       bitsPerComponent: 8,
                       bitsPerPixel: 32,
                       bytesPerRow: 4 * w,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: bitmapInfo(),
                       provider: dataProvider(data: data, size: size)!,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: CGColorRenderingIntent.defaultIntent)
    }
    
    func toData(vflip: Bool = false) -> UnsafeMutableRawPointer? {
        let width = self.width
        let height = self.height

        // Allocate memory
        guard let data = malloc(height * width * 4) else { return nil; }
        let rawBitmapInfo =
            CGImageAlphaInfo.noneSkipLast.rawValue |
                CGBitmapInfo.byteOrder32Big.rawValue
        let bitmapContext = CGContext(data: data,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 4 * width,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: rawBitmapInfo)

        // Flip image vertically if requested
        if vflip {
            bitmapContext?.translateBy(x: 0.0, y: CGFloat(height))
            bitmapContext?.scaleBy(x: 1.0, y: -1.0)
        }

        // Call 'draw' to fill the data array
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        bitmapContext?.draw(self, in: rect)
        return data
    }
    
    func toTexture(device: MTLDevice, vflip: Bool = true) -> MTLTexture? {
        let width = self.width
        let height = self.height
        
        guard let data = toData(vflip: vflip) else { return nil }

        // Use a texture descriptor to create a texture
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLPixelFormat.rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false)
        let texture = device.makeTexture(descriptor: textureDescriptor)

        // Copy data
        let region = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: 4 * width)

        free(data)
        return texture
    }
}
