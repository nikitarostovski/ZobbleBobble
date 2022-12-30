//
//  ZPBody.h
//  ZobbleBobble
//
//  Created by Rost on 19.11.2022.
//

#import <Foundation/Foundation.h>

@class ZPWorld;

@interface ZPBody : NSObject

@property float radius;
@property (readonly) CGPoint position;
@property CGRect color;
@property (nonatomic) void *body;

@property BOOL isRemoving;

- (id)initWithRadius:(float)radius IsDynamic:(BOOL)isDynamic Position:(CGPoint)position Color:(CGRect)color Density:(float)density Friction:(float)friction Restitution:(float)restitution AtWorld:(ZPWorld *)world;

@end
