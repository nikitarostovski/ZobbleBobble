//
//  ZPWorld.h
//  ZobbleBobble
//
//  Created by Rost on 18.11.2022.
//

#import <Foundation/Foundation.h>
#import "ZPWorldDef.h"

typedef void (^RenderDataPassBlock)(int,    // paricle count
                                    void *, // particle positions
                                    void *, // particle velocities
                                    void *, // paricle colors
                                    int,    // circle count
                                    void *, // circle positions
                                    void *, // circle radii
                                    void *);// circle colors

@class ZPBody;

@interface ZPWorld : NSObject

@property (nonatomic) void *world;
@property (nonatomic) void *particleSystem;

- (id)initWithWorldDef:(ZPWorldDef *)def;
/// Steps physics simulation
/// - Parameters:
///   - timeStep: time since last step
///   - velocityIterations: liquidFun's `velocityIterations`
///   - positionIterations: liquidFun's `positionIterations`
///   - particleIterations: liquidFun's `particleIterations`
- (void)worldStep:(CFTimeInterval)timeStep
VelocityIterations:(int)velocityIterations
PositionIterations:(int)positionIterations
ParticleIterations:(int)particleIterations;

- (void)requestRenderDataWithCompletionHandler:(RenderDataPassBlock)completion;

/// Adds a circle shaped object
/// - Parameters:
///   - position: circle center
///   - radius: radius
///   - color: fill color
- (void)addCircleWithCenter:(CGPoint)position
                     Radius:(CGFloat)radius
                      Color:(CGRect)color;

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

/// Removes particle at index `index` from physics simulation
/// - Parameter index: index of particle to remove
- (void)removeParticleAt:(int)index;

@end
