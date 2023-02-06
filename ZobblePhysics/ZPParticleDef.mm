//
//  ZPParticleDef.mm
//  ZobblePhysics
//
//  Created by Rost on 10.01.2023.
//

#import "ZPParticleDef.h"
#import "ZPParticle.h"
#import "Box2D.h"

@implementation ZPParticleDef

- (id)initWithState:(ZPParticleState)state
    ContactBehavior:(ZPParticleContactBehavior)staticContactBehavior
FreezeVelocityThreshold:(CGFloat)freezeVelocityThreshold
       GravityScale:(CGFloat)gravityScale
              Flags:(uint32)currentFlags
    ExplosionRadius:(CGFloat)explosionRadius;
{
    self.state = state;
    self.staticContactBehavior = staticContactBehavior;
    self.freezeVelocityThreshold = freezeVelocityThreshold;
    self.gravityScale = gravityScale;
    self.currentFlags = currentFlags;
    self.explosionRadius = explosionRadius;

    self = [super init];
    return self;
}

@end
