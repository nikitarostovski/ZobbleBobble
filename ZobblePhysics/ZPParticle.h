//
//  ZPParticle.h
//  ZobbleBobble
//
//  Created by Rost on 15.01.2023.
//

#import <Foundation/Foundation.h>
#import "Box2D.h"

enum ZPParticleType {
    ZPParticleTypeCore,
    ZPParticleTypeComet
};

enum ZPParticleState {
    ZPParticleStateStatic,
    ZPParticleStateDynamic
};

enum ZPParticleContactBehavior {
    ZPParticleContactBehaviorNone,
    ZPParticleContactBehaviorBecomeLiquid,
    ZPParticleContactBehaviorExplosive
};

enum ZPParticleStaticBehavior {
    ZPParticleStaticBehaviorNone,
    ZPParticleStaticBehaviorBecomeCore
};

enum ZPParticleGravityBehavior {
    ZPParticleGravityBehaviorNone,
    ZPParticleGravityBehaviorLimited,
    ZPParticleGravityBehaviorUnlimited
};

class ZPParticle {
public:
    ZPParticleType type;
    ZPParticleState state;
    ZPParticleContactBehavior contactBehavior;
    ZPParticleStaticBehavior staticBehavior;
    ZPParticleGravityBehavior gravityBehavior;

    uint32 getDefaultFlagsForCurrentType() {
        switch (state) {
            case ZPParticleStateStatic:
                return b2_wallParticle | b2_particleContactListenerParticle | b2_fixtureContactListenerParticle;
            case ZPParticleStateDynamic:
                return b2_viscousParticle | b2_tensileParticle | b2_particleContactListenerParticle | b2_fixtureContactListenerParticle;
        }
    }
};
