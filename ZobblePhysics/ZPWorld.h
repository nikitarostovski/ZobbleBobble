//
//  ZPWorld.h
//  ZobbleBobble
//
//  Created by Rost on 18.11.2022.
//

#import <Foundation/Foundation.h>
#import "ZPWorldDef.h"

@class ZPBody;

@interface ZPWorld : NSObject

@property (nonatomic) void *world;
@property (nonatomic) void *particleSystem;

@property void *liquidPositions;
@property void *liquidColors;
@property void *liquidVelocities;
@property (nonatomic) int liquidCount;


- (id)initWithWorldDef:(ZPWorldDef *)def;
- (void)worldStep:(CFTimeInterval)timeStep
VelocityIterations:(int)velocityIterations
PositionIterations:(int)positionIterations
ParticleIterations:(int)particleIterations;


/// Adds a particle with given parameters
/// - Parameters:
///   - position: center point in world space
///   - color: particle initial color value
///   - flags: physical flags of particle
///   - isStatic: if belongs to core
///   - gravityScale: gravity scale, 0 is zero, 1 is planet gravity radius
///   - freezeVelocityThreshold: speed threshold for particle to become static
///   - becomesLiquidOnContact: shold become liquid after contact with static
///   - explosionRadius: radius of explosion if explosive
///   - shootImpulse: power of missle shot
- (void)addParticleWithPosition:(CGPoint)position
                          Color:(CGRect)color
                          Flags:(unsigned int)flags
                       IsStatic:(BOOL)isStatic
                   GravityScale:(CGFloat)gravityScale
        FreezeVelocityThreshold:(CGFloat)freezeVelocityThreshold
         BecomesLiquidOnContact:(BOOL)becomesLiquidOnContact
                ExplosionRadius:(CGFloat)explosionRadius
                   ShootImpulse:(CGFloat)shootImpulse;

- (void)removeParticleAt:(int)index;

@end
