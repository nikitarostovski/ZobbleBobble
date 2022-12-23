//
//  ZPWorld.mm
//  ZobblePhysics
//
//  Created by Rost on 18.11.2022.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Box2D.h"
#import "ZPWorld.h"
#import "ZPBody.h"
#import "Constants.h"

static uint32 COMET_MASK = b2_elasticParticle | b2_particleContactListenerParticle | b2_fixtureContactListenerParticle | b2_staticPressureParticle | b2_colorMixingParticle;
static uint32 LIQUID_MASK = b2_tensileParticle | b2_viscousParticle | b2_particleContactListenerParticle | b2_fixtureContactListenerParticle | b2_staticPressureParticle | b2_colorMixingParticle;
static uint32 CORE_MASK = b2_wallParticle | b2_particleContactListenerParticle | b2_fixtureContactListenerParticle;

@implementation ZPWorld {
    NSMutableArray *_bodiesToAdd;
    NSMutableArray *_particlesToAdd;
    NSMutableArray *_particleIndicesToDestroy;
}

- (id)initWithGravity:(CGPoint)gravity ParticleRadius:(CGFloat)radius {
    self = [super init];
    
    _bodiesToAdd = [NSMutableArray new];
    _particleIndicesToDestroy = [NSMutableArray new];
    _particlesToAdd = [NSMutableArray new];
    
    b2World *_world = new b2World(b2Vec2(gravity.x, gravity.y));
    _world->SetAllowSleeping(true);
    self.world = _world;
    self.bodies = [NSMutableArray new];
    
    b2ParticleSystemDef particleSystemDef;
    particleSystemDef.radius = radius;
    particleSystemDef.dampingStrength = 0;
    particleSystemDef.gravityScale = 1;
    particleSystemDef.density = 1;
    particleSystemDef.viscousStrength = 0.9;

//    particleSystemDef.repulsiveStrength = -0.2;
    particleSystemDef.ejectionStrength = 0;
    particleSystemDef.staticPressureStrength = 0.0f;
    
    b2ParticleSystem *system = _world->CreateParticleSystem(&particleSystemDef);
    self.particleSystem = system;
    
    return self;
}

- (void)worldStep:(CFTimeInterval)timeStep velocityIterations:(int)velocityIterations positionIterations:(int)positionIterations {
    b2World *_world = (b2World *)self.world;
    _world->Step(timeStep, velocityIterations, positionIterations, 3);
    
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    
    int particleCount = _system->GetParticleCount();
    int particleContactCount = _system->GetContactCount();
    int bodyContactCount = _system->GetBodyContactCount();
    
    b2Vec2 *positionBuffer = _system->GetPositionBuffer();
    b2Vec2 *velocityBuffer = _system->GetVelocityBuffer();
    const b2ParticleContact *particleContactBuffer = _system->GetContacts();
    const b2ParticleBodyContact *bodyContactBuffer = _system->GetBodyContacts();
    const uint32 *flagsBuffer = _system->GetFlagsBuffer();
    
    bool *contactBuffer = new bool[particleCount];
    
    // Apply gravity to bodies
    for (int i = 0; i < self.bodies.count; i++) {
        b2Body *body = (b2Body *)(self.bodies[i].body);
        b2Vec2 pos = body->GetPosition();
        b2Vec2 d = pos - b2Vec2_zero;
        d.Normalize();

        float mass = 10;//body->GetMass()
        float force = GRAVITY_FORCE * mass * 2 / d.LengthSquared();
        body->ApplyForce(d * -force, pos, true);
    }
    
    // Apply gravity to liquids
    for (int i = 0; i < particleCount; i++) {
        contactBuffer[i] = false;
        uint32 flags = flagsBuffer[i];
        if (flags == CORE_MASK) { continue; }
        
        b2Vec2 v = positionBuffer[i];
        
        b2Vec2 d = b2Vec2_zero - v;
        d.Normalize();
        
        float mass = 10;//_system->GetDensity() * 3.141592 * _system->GetRadius() * _system->GetRadius();
        
        float force = GRAVITY_FORCE * mass * 2 / d.LengthSquared();
        _system->ParticleApplyForce(i, d * force);
    }
    
    // Check for particle - body contact
    for (int i = 0; i < bodyContactCount; i++) {
        b2ParticleBodyContact contact = bodyContactBuffer[i];
        int index = contact.index;
        uint32 flags = flagsBuffer[index];
        
        if (flags == COMET_MASK) {
            _system->SetParticleFlags(index, LIQUID_MASK);
        }
        
        if (flags == LIQUID_MASK) {
            contactBuffer[index] = true;
        }
    }
    
    // Check for particle - particle contact
    for (int i = 0; i < particleContactCount; i++) {
        b2ParticleContact contact = particleContactBuffer[i];

        int indexA = contact.GetIndexA();
        int indexB = contact.GetIndexB();
        
        uint32 flagsA = flagsBuffer[indexA];
        uint32 flagsB = flagsBuffer[indexB];
        
        if (flagsA == LIQUID_MASK && flagsB == COMET_MASK) {
            _system->SetParticleFlags(indexB, LIQUID_MASK);
        } else if (flagsA == COMET_MASK && flagsB == LIQUID_MASK) {
            _system->SetParticleFlags(indexA, LIQUID_MASK);
        }
        
        if (flagsA == LIQUID_MASK && flagsB == CORE_MASK) {
            contactBuffer[indexA] = true;
        } else if (flagsA == CORE_MASK && flagsB == LIQUID_MASK) {
            contactBuffer[indexB] = true;
        }
    }
    
    // Check for static particles
    for (int i = 0; i < particleCount; i++) {
        float velocity = velocityBuffer[i].Length();
        uint32 flags = flagsBuffer[i];

        if (flags == LIQUID_MASK && velocity < 4 && contactBuffer[i]) {
            [self replaceParticleAt:i];
        }
    }
    
    // Remove Bodies
    NSMutableArray *toRemove = [NSMutableArray new];
    for (ZPBody *body in self.bodies) {
        if ([body isRemoving]) {
            [toRemove addObject: body];
        }
    }
    for (ZPBody *body in toRemove) {
        _world->DestroyBody((b2Body *)body.body);
        [self.bodies removeObject:body];
    }
    
    // Remove particles
    for (NSNumber *n in _particleIndicesToDestroy) {
        _system->DestroyParticle([n intValue]);
    }
    [_particleIndicesToDestroy removeAllObjects];
    
    
    // Add Bodies
    for (NSDictionary *dict in _bodiesToAdd) {
        float radius = [dict[kBodyRadiusKey] floatValue];
        CGPoint position = [dict[kBodyPositionKey] CGPointValue];
        
        ZPBody *body = [[ZPBody alloc] initWithRadius:radius IsDynamic:false Position:position Density:1 Friction:1 Restitution:0 Category:CAT_CORE AtWorld: self];
        [self.bodies addObject:body];
    }
    [_bodiesToAdd removeAllObjects];
    
    // Add particles
    for (NSDictionary *dict in _particlesToAdd) {
        NSArray<NSValue *> *polygon = dict[kBodyPolygonKey];
        BOOL isStatic = [dict[kBodyIsStaticKey] boolValue];
        CGPoint position = [dict[kBodyPositionKey] CGPointValue];
        b2Vec2 *pts = new b2Vec2[polygon.count];
        for (int i = 0; i < polygon.count; i++) {
            NSValue *v = polygon[i];
            CGPoint pt = [v CGPointValue];
            b2Vec2 p = *new b2Vec2(pt.x, pt.y);
            pts[i] = p;
        }
        b2PolygonShape shape;
        shape.Set(pts, (int32)polygon.count);
        
        b2ParticleGroupDef particleGroupDef;
        if (isStatic) {
            particleGroupDef.flags = CORE_MASK;
        } else {
            particleGroupDef.flags = COMET_MASK;
        }
        particleGroupDef.position.Set(position.x, position.y);
        particleGroupDef.shape = &shape;
        particleGroupDef.strength = 1;
        
        b2ParticleColor color;
        color.Set(255, 0, 0, 255);
        particleGroupDef.color = color;
        
        b2ParticleSystem *_particleSystem = (b2ParticleSystem *)self.particleSystem;
        _particleSystem->CreateParticleGroup(particleGroupDef);
    }
    [_particlesToAdd removeAllObjects];
    
    // Update render data
    self.liquidCount = _system->GetParticleCount();
    self.liquidPositions = _system->GetPositionBuffer();
    self.liquidColors = _system->GetColorBuffer();
    
    int circleBodyCount = (int)self.bodies.count;
    b2Vec2 *circleBodiesPositions = new b2Vec2[self.circleBodyCount];
    float *circleBodiesRadii = new float[self.circleBodyCount];
    b2ParticleColor *circleBodiesColors = new b2ParticleColor[self.circleBodyCount];
    
    for (int i = 0; i < self.circleBodyCount; i++) {
        CGPoint pos = self.bodies[i].position;
        b2ParticleColor color;
        color.Set(0, 255, 0, 255);
        
        circleBodiesPositions[i] = b2Vec2(pos.x, pos.y);
        circleBodiesColors[i] = color;
        circleBodiesRadii[i] = self.bodies[i].radius;
    }
    
    self.circleBodiesPositions = circleBodiesPositions;
    self.circleBodiesRadii = circleBodiesRadii;
    self.circleBodiesColors = circleBodiesColors;
    self.circleBodyCount = circleBodyCount;
}

- (void)addBodyWithRadius:(float)radius Position:(CGPoint)position {
    NSDictionary *dict = @{kBodyRadiusKey: @(radius), kBodyPositionKey: @(position)};
    if (![_bodiesToAdd containsObject:dict]) {
        [_bodiesToAdd addObject:dict];
    }
}

- (void)addLiquidWithPolygon:(NSArray<NSValue *> *)polygon Position:(CGPoint)position IsStatic:(BOOL)isStatic {
    NSDictionary *dict = @{kBodyPolygonKey: polygon, kBodyPositionKey: @(position), kBodyIsStaticKey: @(isStatic)};
    [_particlesToAdd addObject:dict];
}

- (void)replaceParticleAt:(int)index {
    if ([_particleIndicesToDestroy containsObject:@(index)]) {
        return;
    }
    self.onHarden(index);
    
    
//    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
//    b2Vec2 *positionBuffer = _system->GetPositionBuffer();
//
//    b2Vec2 pos = positionBuffer[index];
//
//    int vertexCount = 4;
//    float radius = _system->GetRadius();
//
//    NSMutableArray<NSValue *> *polygon = [NSMutableArray new];
//    for (int i = 0; i < vertexCount; i++) {
//        CGFloat a = 2 * M_PI * i / vertexCount;
//        CGPoint v = CGPointMake(pos.x + radius * cos(a), pos.y + radius * sin(a));
//        NSValue *val = [NSValue valueWithCGPoint:v];
//        [polygon addObject: val];
//    }

    
//    [_particleIndicesToDestroy addObject:@(index)];
//    _system->SetParticleFlags(index, CORE_MASK);
}

- (void)removeParticleAt:(int)index {
    [_particleIndicesToDestroy addObject:@(index)];
//    [_particleIndicesToDestroy removeObject:@(index)];
//    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
//    _system->DestroyParticle(index);
}

- (void)removeBodyAt:(int)index {
    self.bodies[index].isRemoving = YES;
}

@end
