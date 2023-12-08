//
//  ZobbleWorld.mm
//  ZobblePhysics
//
//  Created by Никита Ростовский on 09.10.2023.
//

#import "ZobbleWorld.h"
#import "physics.hpp"
#import "thread_pool.hpp"
#import "vec.hpp"

@implementation ZobbleWorld {
//    NSLock *_lock;
    PhysicSolver *_solver;
    
    CGSize _worldSize;
}

- (id)initWithSize:(CGSize)size {
    self = [super init];
    
    _worldSize = size;
//    _lock = [NSLock new];
    
    const IVec2 world_size{(int)size.width, (int)size.height};
    _solver = new PhysicSolver(world_size);
    
    [NSTimer scheduledTimerWithTimeInterval:1.0/60.0
                                     target:self
                                   selector:@selector(step:)
                                   userInfo:nil
                                    repeats:YES];
    
    return self;
}

- (void)step:(NSTimer *)timer {
//    [_lock lock];
    float dt = [timer timeInterval];
    
    _solver->update((float)dt);
    
    int count = (int)_solver->objects.size();
    void *particles = (void *)_solver->objects.data.data();
    [self.delegate worldDidUpdateWithParticles: particles Count: count];
//    [_lock unlock];
}

- (void)addParticleWithPos:(CGPoint)pos Color:(simd_uchar4)color {
    Vec2 p = Vec2((float)pos.x + _worldSize.width / 2,
                  (float)pos.y + _worldSize.height / 2);
//    [_lock lock];
    _solver->createObject(p, color);
//    [_lock unlock];
}

@end
