//
//  ZPSoftBody.h
//  ZobblePhysics
//
//  Created by Rost on 20.11.2022.
//

#import <Foundation/Foundation.h>
#import "ZPBody.h"

@class ZPWorld;

@interface ZPSoftBody : ZPBody

@property NSArray<NSValue *> *positions;
@property NSArray<NSValue *> *colors;

- (id)initWithPolygon:(NSArray<NSValue *> *)polygon Position:(CGPoint)position Color:(CGRect)color AtWorld:(ZPWorld *)world;

@end
