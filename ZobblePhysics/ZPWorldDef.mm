//
//  ZPWorldDef.m
//  ZobblePhysics
//
//  Created by Rost on 06.02.2023.
//

#import "ZPWorldDef.h"

@implementation ZPWorldDef

- (id)init {
    self = [super init];
    
    self.strictContactCheck = false;
    self.density = 1.0f;
    self.gravityScale = 1.0f;
    self.radius = 1.0f;
    self.maxCount = 0;

    // Initialize physical coefficients to the maximum values that
    // maintain numerical stability.
    self.pressureStrength = 0.05f;
    self.dampingStrength = 1.0f;
    self.elasticStrength = 0.25f;
    self.springStrength = 0.25f;
    self.viscousStrength = 0.25f;
    self.surfaceTensionPressureStrength = 0.2f;
    self.surfaceTensionNormalStrength = 0.2f;
    self.repulsiveStrength = 1.0f;
    self.powderStrength = 0.5f;
    self.ejectionStrength = 0.5f;
    self.staticPressureStrength = 0.2f;
    self.staticPressureRelaxation = 0.2f;
    self.staticPressureIterations = 8;
    self.colorMixingStrength = 0.5f;
    self.destroyByAge = true;
    self.lifetimeGranularity = 1.0f / 60.0f;
    
    return self;
}

@end
