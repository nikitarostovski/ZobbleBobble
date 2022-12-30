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
    NSMutableArray<ZPBody *> *_bodies;
    NSMutableArray *_bodiesToAdd;
    NSMutableArray *_particlesToAdd;
    NSMutableArray *_particleIndicesToDestroy;
}

const float rotation = 1000;

- (id)initWithGravity:(CGPoint)gravity ParticleRadius:(CGFloat)radius {
    self = [super init];
    
    _bodies = [NSMutableArray new];
    _bodiesToAdd = [NSMutableArray new];
    _particleIndicesToDestroy = [NSMutableArray new];
    _particlesToAdd = [NSMutableArray new];
    
    b2World *_world = new b2World(b2Vec2(gravity.x, gravity.y));
    _world->SetAllowSleeping(true);
    
    self.world = _world;
    
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
    _world->Step(timeStep, velocityIterations, positionIterations, 2);
    
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    
    int particleCount = _system->GetParticleCount();
    int particleContactCount = _system->GetContactCount();
    int bodyContactCount = _system->GetBodyContactCount();
    
    b2Vec2 *positionBuffer = _system->GetPositionBuffer();
    b2Vec2 *velocityBuffer = _system->GetVelocityBuffer();
    b2ParticleColor *colorBuffer = _system->GetColorBuffer();
    const b2ParticleContact *particleContactBuffer = _system->GetContacts();
    const b2ParticleBodyContact *bodyContactBuffer = _system->GetBodyContacts();
    const uint32 *flagsBuffer = _system->GetFlagsBuffer();
    
    bool *contactBuffer = new bool[particleCount];
    
    // Apply gravity to bodies
//    for (int i = 0; i < _bodies.count; i++) {
//        b2Body *body = (b2Body *)(_bodies[i].body);
//        b2Vec2 pos = body->GetPosition();
//        b2Vec2 d = pos - b2Vec2_zero;
//        d.Normalize();
//
//        float mass = 10;//body->GetMass()
//        float force = GRAVITY_FORCE * mass * 2 / d.LengthSquared();
//        body->ApplyForce(d * -force, pos, true);
        
//        check against core angular velocity
//        float amount = rotation;
//        const b2Transform xfm = body->GetTransform();
//        const b2Vec2 p = body->GetPosition();//xfm.p;// - worldPoint;
//        const float32 c = cos(amount);
//        const float32 s = sin(amount);
//        const float32 x = p.x * c - p.y * s;
//        const float32 y = p.x * s + p.y * c;
//        const b2Vec2 pos2 = b2Vec2(x, y);// + worldPoint;
//        const float32 angle = xfm.q.GetAngle() + amount;
//        body->SetTransform(pos2, angle);
        
        
        // Calculate Tangent Vector
//        b2Vec2 radius = body->GetPosition();
//        b2Vec2 tangent = radius.Skew();
//        tangent.Normalize();
//        body->SetLinearVelocity(rotation * timeStep * tangent);
//    }
    
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
        b2Vec2 pos = b2Vec2(positionBuffer[i].Length(), 0);//positionBuffer[i];
        b2Vec2 stepPos = b2Vec2(pos.Length() * cos(rotation), pos.Length() * sin(rotation));
//        float dist = (pos - stepPos).Length();
//        float idleVelocity = dist / timeStep;
//        NSLog(@"%g %g", velocity, idleVelocity);
//        velocity -= idleVelocity;
        
//        b2Vec2 radius = pos;
//        b2Vec2 tangent = radius.Skew();
//        tangent.Normalize();
//        float idleVelocity = (rotation * timeStep * tangent).Length();
//        NSLog(@"%g %g", velocity, idleVelocity);
//        velocity -= idleVelocity;
        
        uint32 flags = flagsBuffer[i];

        if (flags == LIQUID_MASK && velocity < 3 && contactBuffer[i]) {
            CGRect color = CGRectMake(colorBuffer[i].r, colorBuffer[i].g, colorBuffer[i].b, 255);
            [self replaceParticleAt:i Color: color];
        }
    }
    
    // Remove Bodies
    NSMutableArray *toRemove = [NSMutableArray new];
    for (ZPBody *body in _bodies) {
        if ([body isRemoving]) {
            [toRemove addObject: body];
        }
    }
    for (ZPBody *body in toRemove) {
        _world->DestroyBody((b2Body *)body.body);
        [_bodies removeObject:body];
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
        CGRect color = [dict[kBodyColorKey] CGRectValue];
        ZPBody *body = [[ZPBody alloc] initWithRadius:radius IsDynamic:false Position:position Color:color Density:1 Friction:1 Restitution:0 AtWorld: self];
        [_bodies addObject:body];
    }
    [_bodiesToAdd removeAllObjects];
    
    // Add particles
    for (NSDictionary *dict in _particlesToAdd) {
        NSArray<NSValue *> *polygon = dict[kBodyPolygonKey];
        BOOL isStatic = [dict[kBodyIsStaticKey] boolValue];
        CGPoint position = [dict[kBodyPositionKey] CGPointValue];
        CGRect col = [dict[kBodyColorKey] CGRectValue];
        
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
        color.Set(col.origin.x, col.origin.y, col.size.width, 1);
        particleGroupDef.color = color;
        
        b2ParticleSystem *_particleSystem = (b2ParticleSystem *)self.particleSystem;
        _particleSystem->CreateParticleGroup(particleGroupDef);
    }
    [_particlesToAdd removeAllObjects];
    
    // Update render data
    self.liquidPositions = _system->GetPositionBuffer();
    self.liquidVelocities = _system->GetVelocityBuffer();
    self.liquidColors = _system->GetColorBuffer();
    self.liquidCount = _system->GetParticleCount();
    
    int circleBodyCount = (int)_bodies.count;
    b2Vec2 *circleBodiesPositions = new b2Vec2[circleBodyCount];
    float32 *circleBodiesRadii = new float32[circleBodyCount];
    b2ParticleColor *circleBodiesColors = new b2ParticleColor[circleBodyCount];
    
    for (int i = 0; i < circleBodyCount; i++) {
        CGPoint pos = _bodies[i].position;
        CGRect col = _bodies[i].color;
        b2ParticleColor color;
        color.Set(col.origin.x, col.origin.y, col.size.width, 1);
        
        circleBodiesPositions[i] = b2Vec2(pos.x, pos.y);
        circleBodiesColors[i] = color;
        circleBodiesRadii[i] = _bodies[i].radius;
    }
    
    self.circleBodiesPositions = circleBodiesPositions;
    self.circleBodiesRadii = circleBodiesRadii;
    self.circleBodiesColors = circleBodiesColors;
    self.circleBodyCount = circleBodyCount;
}

- (void)addBodyWithRadius:(float)radius Position:(CGPoint)position Color:(CGRect)color {
    NSDictionary *dict = @{kBodyRadiusKey: @(radius), kBodyPositionKey: @(position), kBodyColorKey: [NSValue valueWithCGRect:color]};
    if (![_bodiesToAdd containsObject:dict]) {
        [_bodiesToAdd addObject:dict];
    }
}

- (void)addLiquidWithPolygon:(NSArray<NSValue *> *)polygon Color:(CGRect)color Position:(CGPoint)position IsStatic:(BOOL)isStatic {
    NSDictionary *dict = @{kBodyPolygonKey: polygon, kBodyPositionKey: @(position), kBodyIsStaticKey: @(isStatic), kBodyColorKey: [NSValue valueWithCGRect:color]};
    [_particlesToAdd addObject:dict];
}

- (void)replaceParticleAt:(int)index Color:(CGRect)color {
    if ([_particleIndicesToDestroy containsObject:@(index)]) {
        return;
    }
    self.onHarden(index, color);
    
    
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
    _bodies[index].isRemoving = YES;
}

@end
