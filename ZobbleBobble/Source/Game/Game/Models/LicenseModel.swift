//
//  LicenseModel.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation
import Levels

struct LicenseModel: Codable {
    struct EmptyValue: Codable { }
    struct Limit<T: Codable>: Codable {
        let value: T
        let fine: Int
    }
    
    struct SectorModel: Codable {
        /// Degrees
        let startAngle: Float
        /// Degrees
        let sectorSize: Float
    }
    
    let price: Int
    let radiusLimit: Limit<Float>
    let sectorLimit: Limit<[SectorModel]>
    let materialWhitelist: Limit<[MaterialType]>
    let totalParticleAmountLimit: Limit<Int>
    let outerSpaceLimit: Limit<EmptyValue>
}
