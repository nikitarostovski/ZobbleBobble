//
//  LicenseModel.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation
import Levels

struct LicenseModel {
    struct Limit<T> {
        let value: T
        let fine: Int
    }
    
    let price: Int
    let radiusLimit: Limit<CGFloat>
    let sectorLimit: Limit<[CGPoint]>
    let materialWhitelist: Limit<[MaterialType]>
    let totalParticleAmountLimit: Limit<Int>
    let outerSpaceLimit: Limit<Void>
}
