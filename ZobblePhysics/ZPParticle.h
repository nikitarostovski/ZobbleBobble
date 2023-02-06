//
//  ZPParticle.h
//  ZobbleBobble
//
//  Created by Rost on 15.01.2023.
//

#import <Foundation/Foundation.h>
#import "Box2D.h"

enum ZPParticleState {
    ZPParticleStateStatic,
    ZPParticleStateDynamic
};

enum ZPParticleContactBehavior {
    ZPParticleContactBehaviorNone,
    ZPParticleContactBehaviorBecomeLiquid,
    ZPParticleContactBehaviorExplosive
};

class ZPParticle {
public:
    ZPParticleState state;
    ZPParticleContactBehavior staticContactBehavior;
    CGFloat freezeVelocityThreshold;
    CGFloat gravityScale;
    uint32 currentFlags;
    bool isDestroying = false;
    CGFloat explosionRadius;
};
