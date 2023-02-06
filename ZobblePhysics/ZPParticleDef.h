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
@property ZPParticleContactBehavior staticContactBehavior;
@property CGFloat freezeVelocityThreshold;
@property CGFloat gravityScale;
@property uint32 currentFlags;
@property CGFloat explosionRadius;

@property CGPoint initialForce;

- (id)initWithState:(ZPParticleState)state
    ContactBehavior:(ZPParticleContactBehavior)staticContactBehavior
FreezeVelocityThreshold:(CGFloat)freezeVelocityThreshold
       GravityScale:(CGFloat)gravityScale
              Flags:(uint32)currentFlags
    ExplosionRadius:(CGFloat)explosionRadius;

@end
