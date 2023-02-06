//
//  ZPWorld.h
//  ZobbleBobble
//
//  Created by Rost on 18.11.2022.
//

#import <Foundation/Foundation.h>

@class ZPBody;

@interface ZPWorld : NSObject

@property (nonatomic) void *world;
@property (nonatomic) void *particleSystem;

@property (nonatomic) void *circleBodiesPositions;
@property (nonatomic) void *circleBodiesRadii;
@property (nonatomic) void *circleBodiesColors;
@property (nonatomic) int circleBodyCount;

@property void *liquidPositions;
@property void *liquidColors;
@property void *liquidVelocities;
@property (nonatomic) int liquidCount;


- (id)initWithGravityCenter:(CGPoint)center GravityRadius:(CGFloat)gravityRadius ParticleRadius:(CGFloat)radius;
- (void)worldStep:(CFTimeInterval)timeStep velocityIterations:(int)velocityIterations positionIterations:(int)positionIterations;


/// Adds a particle with given parameters
/// - Parameters:
///   - position: center point in world space
///   - color: particle initial color value
///   - flags: physical flags of particle
///   - isStatic: if belongs to core
///   - gravityScale: gravity scale, 0 is zero, 1 is planet gravity radius
///   - freezeVelocityThreshold: speed threshold for particle to become static
///   - staticContactBehavior: contact behavior. ZPParticleContactBehavior
- (void)addParticleWithPosition:(CGPoint)position
                          Color:(CGRect)color
                          Flags:(unsigned int)flags
                       IsStatic:(BOOL)isStatic
                   GravityScale:(CGFloat)gravityScale
        FreezeVelocityThreshold:(CGFloat)freezeVelocityThreshold
          StaticContactBehavior:(int)staticContactBehavior
                ExplosionRadius:(CGFloat)explosionRadius;

- (void)removeParticleAt:(int)index;

@end
