//
//  ZPBody.h
//  ZobbleBobble
//
//  Created by Rost on 19.11.2022.
//

#import <Foundation/Foundation.h>

@class ZPWorld;

@interface ZPBody : NSObject

@property NSArray<NSValue *> *polygon;
@property (nonatomic) void *body;

@property BOOL isRemoving;

- (id)initWithPolygon:(NSArray<NSValue *> *)points IsDynamic:(BOOL)isDynamic Position:(CGPoint)position Density:(float)density Friction:(float)friction Restitution:(float)restitution Category:(int)category AtWorld:(ZPWorld *)world;

@end
