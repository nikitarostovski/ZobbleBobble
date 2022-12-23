//
//  ZPWorld.h
//  ZobbleBobble
//
//  Created by Rost on 18.11.2022.
//

#import <Foundation/Foundation.h>

static NSString *kBodyPolygonKey = @"body_polygon";
static NSString *kBodyRadiusKey = @"body_radius";
static NSString *kBodyPositionKey = @"body_position";
static NSString *kBodyIsStaticKey = @"body_static";

typedef void(^OnParticleHarden)(int);

@class ZPBody;

@interface ZPWorld : NSObject

@property (nonatomic) void *world;
@property (nonatomic) void *particleSystem;

@property (nonatomic) NSMutableArray<ZPBody *> *bodies;

@property (nonatomic) void *circleBodiesPositions;
@property (nonatomic) void *circleBodiesRadii;
@property (nonatomic) void *circleBodiesColors;
@property (nonatomic) int circleBodyCount;

@property (nonatomic) void *liquidPositions;
@property (nonatomic) void *liquidColors;
@property (nonatomic) int liquidCount;
@property (nonatomic, copy) OnParticleHarden onHarden;


- (id)initWithGravity:(CGPoint)gravity ParticleRadius:(CGFloat)radius;
- (void)worldStep:(CFTimeInterval)timeStep velocityIterations:(int)velocityIterations positionIterations:(int)positionIterations;

- (void)addBodyWithRadius:(float)radius Position:(CGPoint)position;
- (void)addLiquidWithPolygon:(NSArray<NSValue *> *)polygon Position:(CGPoint)position IsStatic:(BOOL)isStatic;

- (void)removeBodyAt:(int)index;
- (void)removeParticleAt:(int)index;

@end
