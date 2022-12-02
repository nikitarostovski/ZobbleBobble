//
//  ZPBody.h
//  ZobbleBobble
//
//  Created by Rost on 19.11.2022.
//

#import <Foundation/Foundation.h>

@class ZPWorld;

@interface ZPBody : NSObject

- (void)stepAtWorld:(ZPWorld *)world;

@end
