//
//  ZPRigidBody.h
//  ZobblePhysics
//
//  Created by Rost on 20.11.2022.
//

#import <Foundation/Foundation.h>
#import "ZPBody.h"

@class ZPWorld;

@interface ZPRigidBody : ZPBody

@property CGPoint position;
@property CGFloat angle;

- (id)initWithPolygon:(NSArray<NSValue *> *)points IsDynamic:(BOOL)isDynamic Position:(CGPoint)position Density:(float)density Friction:(float)friction Restitution:(float)restitution AtWorld:(ZPWorld *)world;
- (id)initWithEdge:(CGPoint)p1 To:(CGPoint)p2 IsDynamic:(BOOL)isDynamic Position:(CGPoint)position Density:(float)density Friction:(float)friction Restitution:(float)restitution AtWorld:(ZPWorld *)world;
- (id)initWithRadius:(float)radius IsDynamic:(BOOL)isDynamic Position:(CGPoint)position Density:(float)density Friction:(float)friction Restitution:(float)restitution AtWorld:(ZPWorld *)world;

@end
