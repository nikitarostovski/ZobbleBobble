//
//  ZobbleWorld.h
//  ZobblePhysics
//
//  Created by Никита Ростовский on 09.10.2023.
//

#import <Foundation/Foundation.h>
#import <simd/SIMD.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZobbleWorldDelegate
- (void)worldDidUpdateWithParticles:(void *)particles Count:(int)particleCount;
@end


@interface ZobbleWorld : NSObject

@property (weak, nonatomic) id<ZobbleWorldDelegate> delegate;

- (id)initWithSize:(CGSize)size;
- (void)addParticleWithPos:(CGPoint)pos Color:(simd_uchar4)color;

@end

NS_ASSUME_NONNULL_END
