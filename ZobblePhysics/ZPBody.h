//
//  ZPBody.h
//  ZobbleBobble
//
//  Created by Rost on 19.11.2022.
//

#import <Foundation/Foundation.h>

@class ZPWorld;

@interface ZPBody : NSObject

@property int category;
@property BOOL isDestroying;
@property (nonatomic, copy) void (^onContact)(ZPBody * otherBody);
@property (nonatomic, weak) ZPWorld *world;

- (void)stepAtWorld:(ZPWorld *)world;
- (void)destroy;

@end
