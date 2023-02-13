//
//  ZPParticleDef.h
//  ZobbleBobble
//
//  Created by Rost on 10.01.2023.
//

#import <Foundation/Foundation.h>
#import "ZPParticle.h"

@interface ZPParticleDef: NSObject

@property ZPParticleState state;
@property BOOL becomesLiquidOnContact;
@property CGFloat freezeVelocityThreshold;
@property CGFloat gravityScale;
@property uint32 currentFlags;
@property CGFloat explosionRadius;
@property CGFloat shootImpulse;

@property CGPoint initialForce;

- (id)initWithState:(ZPParticleState)state
BecomesLiquidOnContact:(BOOL)becomesLiquidOnContact
FreezeVelocityThreshold:(CGFloat)freezeVelocityThreshold
       GravityScale:(CGFloat)gravityScale
              Flags:(uint32)currentFlags
    ExplosionRadius:(CGFloat)explosionRadius
       ShootImpulse:(CGFloat)shootImpulse;

@end
