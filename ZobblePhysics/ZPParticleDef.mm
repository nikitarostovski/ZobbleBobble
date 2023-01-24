//
//  ZPParticleDef.mm
//  ZobblePhysics
//
//  Created by Rost on 10.01.2023.
//

#import "ZPParticleDef.h"
#import "ZPParticle.h"

@implementation ZPParticleDef

- (id)initWithType:(ZPParticleType)type
             State:(ZPParticleState)state
   ContactBehavior:(ZPParticleContactBehavior)contactBehavior
    StaticBehavior:(ZPParticleStaticBehavior)staticBehavior
   GravityBehavior:(ZPParticleGravityBehavior)gravityBehavior {

    self.type = type;
    self.state = state;
    self.contactBehavior = contactBehavior;
    self.staticBehavior = staticBehavior;
    self.gravityBehavior = gravityBehavior;

    self = [super init];
    return self;
}

@end
