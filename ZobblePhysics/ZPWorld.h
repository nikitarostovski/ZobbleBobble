//
//  ZPWorld.h
//  ZobbleBobble
//
//  Created by Rost on 18.11.2022.
//

#import <Foundation/Foundation.h>

//static NSString *kBodyPolygonKey = @"body_polygon";
//static NSString *kBodyRadiusKey = @"body_radius";
//static NSString *kBodyColorKey = @"body_color";
//static NSString *kBodyPositionKey = @"body_position";
//static NSString *kBodyIsExplodingKey = @"body_is_exploding";
//static NSString *kBodyIsStaticKey = @"body_static";

//typedef void(^OnParticleHarden)(int, CGRect);

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

- (void)addParticleWithPosition:(CGPoint)position Color:(CGRect)color IsStatic:(BOOL)isStatic IsExplodable:(BOOL) isExplodable;

- (void)removeParticleAt:(int)index;

@end
