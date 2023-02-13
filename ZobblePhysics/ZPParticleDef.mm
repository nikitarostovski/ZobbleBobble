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
BecomesLiquidOnContact:(BOOL)becomesLiquidOnContact
FreezeVelocityThreshold:(CGFloat)freezeVelocityThreshold
       GravityScale:(CGFloat)gravityScale
              Flags:(uint32)currentFlags
    ExplosionRadius:(CGFloat)explosionRadius
       ShootImpulse:(CGFloat)shootImpulse
{
    self.state = state;
    self.becomesLiquidOnContact = becomesLiquidOnContact;
    self.freezeVelocityThreshold = freezeVelocityThreshold;
    self.gravityScale = gravityScale;
    self.currentFlags = currentFlags;
    self.explosionRadius = explosionRadius;
    self.shootImpulse = shootImpulse;

    self = [super init];
    return self;
}

@end
