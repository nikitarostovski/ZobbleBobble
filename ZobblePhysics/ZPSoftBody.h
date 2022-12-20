//
//  ZPSoftBody.h
//  ZobblePhysics
//
//  Created by Rost on 20.11.2022.
//

#import <Foundation/Foundation.h>
#import "ZPBody.h"
#import <simd/simd.h>

@class ZPWorld;

@interface ZPSoftBody : ZPBody

@property NSArray<NSValue *> *positions;
@property NSArray<NSValue *> *colors;

- (id)initWithPolygon:(NSArray<NSValue *> *)polygon Position:(CGPoint)position Color:(CGRect)color Category:(int)category AtWorld:(ZPWorld *)world;

- (void)becomeDynamic;

@end
