//
//  ZPWorld.h
//  ZobbleBobble
//
//  Created by Rost on 18.11.2022.
//

#import <Foundation/Foundation.h>

@interface ZPWorld : NSObject

@property (nonatomic) void *world;
@property (nonatomic) void *particleSystem;

@property (nonatomic) NSMutableArray *bodies;

- (id)initWithGravity:(CGPoint)gravity ParticleRadius:(CGFloat)radius;
- (void)worldStep:(CFTimeInterval)timeStep velocityIterations:(int)velocityIterations positionIterations:(int)positionIterations;

@end
