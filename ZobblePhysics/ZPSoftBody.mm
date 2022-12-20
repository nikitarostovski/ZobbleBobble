//
//  ZPSoftBody.mm
//  ZobblePhysics
//
//  Created by Rost on 20.11.2022.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "ZPSoftBody.h"
#import "ZPWorld.h"
#import "Box2D.h"

typedef NS_ENUM(NSUInteger, ZPSoftBodyState) {
    ZPSoftBodyStateSolidComet,
    ZPSoftBodyStateLiquidComet,
    ZPSoftBodyStateSolidCore
};

@implementation ZPSoftBody {
    b2ParticleGroup *_particleGroup;
    NSDate *_impactStart;
    
    ZPSoftBodyState _state;
}

- (id)initWithPolygon:(NSArray<NSValue *> *)polygon Position:(CGPoint)position Color:(CGRect)color Category:(int)category AtWorld:(ZPWorld *)world {
    self = [super init];
    
    self.world = world;
    self.positions = [NSMutableArray new];
    self.colors = [NSMutableArray new];
    self.category = category;
    
    _state = ZPSoftBodyStateSolidComet;
    
    b2Vec2 *pts = new b2Vec2[polygon.count];
    for (int i = 0; i < polygon.count; i++) {
        NSValue *v = polygon[i];
        CGPoint pt = [v CGPointValue];
        b2Vec2 p = *new b2Vec2(pt.x / SCALE_RATIO, pt.y / SCALE_RATIO);
        pts[i] = p;
    }
    b2PolygonShape shape;
    shape.Set(pts, (int32)polygon.count);
    
    
    
    b2ParticleGroupDef particleGroupDef;
    particleGroupDef.flags = b2_elasticParticle | b2_fixtureContactListenerParticle;
    particleGroupDef.position.Set(position.x / SCALE_RATIO, position.y / SCALE_RATIO);
    particleGroupDef.shape = &shape;
    particleGroupDef.strength = 1;
    particleGroupDef.groupFlags = b2_solidParticleGroup;
    particleGroupDef.color = b2ParticleColor(color.origin.x, color.origin.y, color.size.width, 255);

    b2ParticleSystem *_particleSystem = (b2ParticleSystem *)world.particleSystem;
    _particleGroup = _particleSystem->CreateParticleGroup(particleGroupDef);
    _particleGroup->SetUserData((__bridge void *)self);
    
    [world.bodies addObject:self];
    
    return self;
}

- (void)stepAtWorld:(ZPWorld *)world {
    b2ParticleSystem *_system = (b2ParticleSystem *)world.particleSystem;
    int particleCount = _system->GetParticleCount();
    b2Vec2 *positionBuffer = _system->GetPositionBuffer();
    b2ParticleColor *colorBuffer = _system->GetColorBuffer();

    NSMutableArray *points = [NSMutableArray new];
    NSMutableArray *colors = [NSMutableArray new];
    for (int i = 0; i < particleCount; i++) {
        if (!_particleGroup->ContainsParticle(i)) {
            continue;
        }
        
        b2Vec2 v = positionBuffer[i];
        b2ParticleColor col = colorBuffer[i];
        
        CGPoint p = CGPointMake((v.x) * SCALE_RATIO, v.y * SCALE_RATIO);
        [points addObject:[NSValue valueWithCGPoint:p]];
        CGRect c = CGRectMake(col.r / 255.0, col.g / 255.0, col.b / 255.0, col.a / 255.0);
        [colors addObject:[NSValue valueWithCGRect:c]];
        
        b2Vec2 d = b2Vec2_zero - b2Vec2(p.x, p.y);
        d.Normalize();
        
        float mass = _system->GetDensity() * 3.141592 * _system->GetRadius() * _system->GetRadius();
        
        float force = GRAVITY_FORCE * mass * 2 / d.LengthSquared();
        _system->ParticleApplyForce(i, d * force);
    }
    
    if (_state == ZPSoftBodyStateLiquidComet) {
        b2ParticleSystem *_system = _particleGroup->GetParticleSystem();
        b2Vec2 *velocityBuffer = _system->GetVelocityBuffer();
        
        int start = _particleGroup->GetBufferIndex();
        int count = _particleGroup->GetParticleCount();
        
        for (int i = start; i < start + count; i++) {
            float velocity = velocityBuffer[i].Length();
            uint32 flags = _system->GetParticleFlags(i);
            if (velocity < 3 && flags != b2_wallParticle) {
                [self becomeStaticAt:i];
            }
        }
    }
    
    self.positions = points;
    self.colors = colors;
}

- (void)becomeStaticAt:(int)index {
    if (_state != ZPSoftBodyStateLiquidComet) { return; }
    
    b2ParticleSystem *_system = (b2ParticleSystem *)self.world.particleSystem;
    
    _system->SetParticleFlags(index, b2_wallParticle);
    
    self.category = CAT_CORE;
//    _state = ZPSoftBodyStateSolidCore;
    
//    b2World *_world = (b2World *)self.world.world;
//    _world->
}

- (void)becomeDynamic {
    if (_impactStart != nil || _state == ZPSoftBodyStateLiquidComet) { return; }
    
    b2ParticleSystem *_system = (b2ParticleSystem *)self.world.particleSystem;
    
    int start = _particleGroup->GetBufferIndex();
    int count = _particleGroup->GetParticleCount();
    
    
    NSLog(@"!!! dynamic [%d %d]", start, start + count);
    
    for (int i = start; i < start + count; i++) {
        _system->SetParticleFlags(i, b2_viscousParticle);
    }
    
    _impactStart = [NSDate date];
    _state = ZPSoftBodyStateLiquidComet;
}

- (void)destroy {
    self.isDestroying = true;
}

@end
