//
//  ZPWorld.mm
//  ZobblePhysics
//
//  Created by Rost on 18.11.2022.
//

#import "Box2D.h"
#import "ZPWorld.h"
#import "ZPBody.h"
#import "Constants.h"

@implementation ZPWorld

- (id)initWithGravity:(CGPoint)gravity ParticleRadius:(CGFloat)radius {
    self = [super init];
    
    self.bodies = [NSMutableArray new];
    b2World *_world = new b2World(b2Vec2(gravity.x, gravity.y));
    
    b2ParticleSystemDef particleSystemDef;
    particleSystemDef.radius = radius / SCALE_RATIO;
    particleSystemDef.dampingStrength = 1;
    particleSystemDef.gravityScale = 1;
    particleSystemDef.density = 1;

    self.world = _world;
    
    b2ParticleSystem *system = _world->CreateParticleSystem(&particleSystemDef);
    system->SetStaticPressureIterations(8);
    self.particleSystem = system;
    
    return self;
}

- (void)worldStep:(CFTimeInterval)timeStep velocityIterations:(int)velocityIterations positionIterations:(int)positionIterations {
    b2World *_world = (b2World *)self.world;
    _world->Step(timeStep, velocityIterations, positionIterations, 3);
    
    for (ZPBody *body in self.bodies) {
        [body stepAtWorld:self];
    }
}

@end
