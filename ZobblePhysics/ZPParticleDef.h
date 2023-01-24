//
//  ZPParticleDef.h
//  ZobbleBobble
//
//  Created by Rost on 10.01.2023.
//

#import <Foundation/Foundation.h>
#import "ZPParticle.h"

@interface ZPParticleDef: NSObject
@property ZPParticleType type;
@property ZPParticleState state;
@property ZPParticleContactBehavior contactBehavior;
@property ZPParticleStaticBehavior staticBehavior;
@property ZPParticleGravityBehavior gravityBehavior;

@property CGPoint initialForce;

//- (ZPParticle *)makeUserData;

@end
