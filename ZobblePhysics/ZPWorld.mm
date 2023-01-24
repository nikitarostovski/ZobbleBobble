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
#import "ZPParticle.h"
#import "ZPParticleDef.h"

static NSString *kParticlePositionKey = @"particle_position";
static NSString *kParticleColorKey = @"particle_color";
static NSString *kParticleUserDataKey = @"particle_user_data";

static float kExplosiveDamageRadius = 20.0;
static float kExplosiveImpulse = 1050000;
static float kCometShootImpulse = 1650000;
static float kFreezeVelocityThreshold = 5;

@implementation ZPWorld {
    CGPoint _gravityCenter;
    CGFloat _gravityRadius;
    NSMutableArray<ZPBody *> *_bodies;
    NSMutableArray *_bodiesToAdd;
    NSMutableArray *_particlesToAdd;
    NSMutableArray *_particleIndicesToDestroy;
    
//    b2ParticleGroup *_coreParticleGroup;
//    b2ParticleGroup *_cometParticleGroup;
}

- (id)initWithGravityCenter:(CGPoint)center GravityRadius:(CGFloat)gravityRadius ParticleRadius:(CGFloat)radius {
    self = [super init];
    
    _gravityRadius = gravityRadius;
    _gravityCenter = center;
    _bodies = [NSMutableArray new];
    _bodiesToAdd = [NSMutableArray new];
    _particleIndicesToDestroy = [NSMutableArray new];
    _particlesToAdd = [NSMutableArray new];
    
    b2World *_world = new b2World(b2Vec2(0, 0));
    _world->SetAllowSleeping(true);
    
    self.world = _world;
    
    b2ParticleSystemDef particleSystemDef;
    particleSystemDef.radius = radius;
    particleSystemDef.dampingStrength = 0;
    particleSystemDef.gravityScale = 1;
    particleSystemDef.density = 1;
    particleSystemDef.viscousStrength = 0.9;
    particleSystemDef.repulsiveStrength = 1.2;
    particleSystemDef.ejectionStrength = 0;
    particleSystemDef.staticPressureStrength = 0.0f;
    
    b2ParticleSystem *system = _world->CreateParticleSystem(&particleSystemDef);
//    system->GetStuckCandidates()
    self.particleSystem = system;
    
//    b2ParticleGroupDef coreGroupDef;
//    coreGroupDef.groupFlags = b2_rigidParticleGroup | b2_particleGroupCanBeEmpty;
//    _coreParticleGroup = system->CreateParticleGroup(coreGroupDef);
//
//    b2ParticleGroupDef cometGroupDef;
//    cometGroupDef.groupFlags = b2_solidParticleGroup | b2_particleGroupCanBeEmpty;
//    _cometParticleGroup = system->CreateParticleGroup(cometGroupDef);
    
    return self;
}

- (void)worldStep:(CFTimeInterval)timeStep velocityIterations:(int)velocityIterations positionIterations:(int)positionIterations {
    b2World *_world = (b2World *)self.world;
    _world->Step(timeStep, velocityIterations, positionIterations, 2);
    
//    int staticCount = 0;
//    int dynamicCount = 0;
//    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
//    for (int i = 0; i < _system->GetParticleCount(); i++) {
//        ZPParticle *ud = (ZPParticle *)_system->GetUserDataBuffer()[i];
//        if (ud->state == ZPParticleStateStatic) {
//            staticCount++;
//        } else if (ud->state == ZPParticleStateDynamic) {
//            dynamicCount++;
//        }
//    }
//    NSLog(@"Static: %d Dynamic: %d Stuck: %d", staticCount, dynamicCount, _system->GetStuckCandidateCount());
    
    [self updateGravity];
    [self processContacts];
    [self checkForStaticParticles];
    [self updateRenderData];
    
    [self createAndRemoveBodies];
}

- (void)updateGravity {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    
    int particleCount = _system->GetParticleCount();
    b2Vec2 *positionBuffer = _system->GetPositionBuffer();
    void **ud = _system->GetUserDataBuffer();
    
    // Liquids
    for (int i = 0; i < particleCount; i++) {
        ZPParticle *userData = (ZPParticle *)ud[i];
        if (userData->gravityBehavior == ZPParticleGravityBehaviorNone) { continue; }
        
        b2Vec2 v = positionBuffer[i];
        b2Vec2 d = b2Vec2(_gravityCenter.x, _gravityCenter.y) - v;
        if (d.Length() > _gravityRadius && userData->gravityBehavior == ZPParticleGravityBehaviorLimited) {
            continue;
        }
        
        d.Normalize();
        float mass = 10;//_system->GetDensity() * 3.141592 * _system->GetRadius() * _system->GetRadius();
        float force = GRAVITY_FORCE * mass * 2 / d.LengthSquared();
        _system->ParticleApplyForce(i, d * force);
    }
}

- (void)processContacts {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    
    int particleCount = _system->GetParticleCount();
    int particleContactCount = _system->GetContactCount();
    
    b2Vec2 *positionBuffer = _system->GetPositionBuffer();
    const b2ParticleContact *particleContactBuffer = _system->GetContacts();
    void** ud = _system->GetUserDataBuffer();
    
    // Check for particle - particle contact
    for (int i = 0; i < particleContactCount; i++) {
        b2ParticleContact contact = particleContactBuffer[i];

        int indexA = contact.GetIndexA();
        int indexB = contact.GetIndexB();
        
        ZPParticle *userDataA = (ZPParticle *)ud[indexA];
        ZPParticle *userDataB = (ZPParticle *)ud[indexB];
        
        if (userDataA->type == ZPParticleTypeComet && userDataA->contactBehavior == ZPParticleContactBehaviorBecomeLiquid && userDataB->type == ZPParticleTypeCore) {
            b2Vec2 pos = positionBuffer[indexA];
            b2ParticleColor col = _system->GetColorBuffer()[indexA];
            
            if ([_particleIndicesToDestroy containsObject:@(indexA)]) {
                break;
            }
            [self removeParticleAt:indexA];
            CGPoint position = CGPointMake(pos.x, pos.y);
            CGRect color = CGRectMake(col.r, col.g, col.b, col.a);
            
            ZPParticleDef *def = [[ZPParticleDef alloc] init];
            def.type = ZPParticleTypeComet;
            def.state = ZPParticleStateDynamic;
            def.staticBehavior = ZPParticleStaticBehaviorBecomeCore;
            def.gravityBehavior = ZPParticleGravityBehaviorUnlimited;
            def.contactBehavior = ZPParticleContactBehaviorNone;
            [self addParticleAt:position Color:color UserData:def];
        } else if (userDataB->type == ZPParticleTypeComet && userDataB->contactBehavior == ZPParticleContactBehaviorBecomeLiquid && userDataA->type == ZPParticleTypeCore) {
            
            b2Vec2 pos = positionBuffer[indexB];
            b2ParticleColor col = _system->GetColorBuffer()[indexB];
            
            if ([_particleIndicesToDestroy containsObject:@(indexB)]) {
                break;
            }
            [self removeParticleAt:indexB];
            CGPoint position = CGPointMake(pos.x, pos.y);
            CGRect color = CGRectMake(col.r, col.g, col.b, col.a);
            
            ZPParticleDef *def = [[ZPParticleDef alloc] init];
            def.type = ZPParticleTypeComet;
            def.state = ZPParticleStateDynamic;
            def.staticBehavior = ZPParticleStaticBehaviorBecomeCore;
            def.gravityBehavior = ZPParticleGravityBehaviorUnlimited;
            def.contactBehavior = ZPParticleContactBehaviorNone;
            [self addParticleAt:position Color:color UserData:def];
        }
        
        b2Vec2 explosionCenter;
        if (userDataA->type == ZPParticleTypeComet &&
            userDataA->contactBehavior == ZPParticleContactBehaviorExplosive &&
            userDataB->contactBehavior != ZPParticleContactBehaviorExplosive) {

            explosionCenter = positionBuffer[indexB];
            [self removeParticleAt:indexA];
        } else if (userDataB->type == ZPParticleTypeComet &&
                   userDataB->contactBehavior == ZPParticleContactBehaviorExplosive &&
                   userDataA->contactBehavior != ZPParticleContactBehaviorExplosive) {

            explosionCenter = positionBuffer[indexA];
            [self removeParticleAt:indexB];
        } else {
            continue;
        }

        for (int i = 0; i < particleCount; i++) {
            b2Vec2 pos = positionBuffer[i];
            float dist = (pos - explosionCenter).Length();
            if (dist < kExplosiveDamageRadius) {
                pos.Normalize();
                b2Vec2 force = pos * kExplosiveImpulse;
                
                [self makeLiquidAt:i Force:CGPointMake(force.x, force.y)];
                _system->GetColorBuffer()[i] = b2ParticleColor(0, 255, 0, 255);
            }
        }
    }
}

- (void)checkForStaticParticles {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    int particleCount = _system->GetParticleCount();
    b2Vec2 *velocityBuffer = _system->GetVelocityBuffer();
    void **ud = _system->GetUserDataBuffer();
    
    for (int i = 0; i < particleCount; i++) {
        float velocity = velocityBuffer[i].Length();
        ZPParticle *userData = (ZPParticle *)ud[i];
        
        if (userData->staticBehavior == ZPParticleStaticBehaviorBecomeCore && velocity < kFreezeVelocityThreshold) {
            [self makeCoreAt:i Force:CGPointMake(0, 0)];
        }
    }
}

- (void)createAndRemoveBodies {
    b2ParticleSystem *_particleSystem = (b2ParticleSystem *)self.particleSystem;
    // Remove particles
    for (NSNumber *n in _particleIndicesToDestroy) {
        [self destroyParticleAt:[n intValue]];
    }
    [_particleIndicesToDestroy removeAllObjects];
    
    // Add particles
    for (NSDictionary *dict in _particlesToAdd) {
        ZPParticleDef *def = dict[kParticleUserDataKey];
        CGPoint position = [dict[kParticlePositionKey] CGPointValue];
        CGRect col = [dict[kParticleColorKey] CGRectValue];
        
        b2ParticleColor color;
        color.Set(col.origin.x, col.origin.y, col.size.width, 1);
        
        ZPParticle *userData = new ZPParticle();
        userData->type = def.type;
        userData->state = def.state;
        userData->contactBehavior = def.contactBehavior;
        userData->staticBehavior = def.staticBehavior;
        userData->gravityBehavior = def.gravityBehavior;
        
        int newIndex = [self createParticleAt:b2Vec2(position.x, position.y) Color:color UserData:userData];
        
        if (def.initialForce.x != 0 && def.initialForce.y != 0) {
            _particleSystem->ParticleApplyForce(newIndex, b2Vec2(def.initialForce.x, def.initialForce.y));
        }
    }
    [_particlesToAdd removeAllObjects];
}

- (void)updateRenderData {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    
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
    
    delete[] circleBodiesPositions;
    delete[] circleBodiesColors;
    delete[] circleBodiesRadii;
}

- (void)addLiquidWithPolygon:(NSArray<NSValue *> *)polygon Color:(CGRect)color Position:(CGPoint)position IsStatic:(BOOL)isStatic IsExplodable:(BOOL) isExplodable {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    
    b2Vec2 *pts = new b2Vec2[polygon.count];
    for (int i = 0; i < polygon.count; i++) {
        NSValue *v = polygon[i];
        CGPoint pt = [v CGPointValue];
        pts[i] = b2Vec2(pt.x, pt.y);
    }
    b2PolygonShape shape;
    shape.Set(pts, (int32)polygon.count);
    
    float32 stride = _system->GetRadius() * 2 * b2_particleStride;
    b2Transform identity;
    identity.SetIdentity();
    b2AABB aabb;
    shape.ComputeAABB(&aabb, identity, 0);
    
    delete[] pts;
    
    for (float32 y = floorf(aabb.lowerBound.y / stride) * stride; y < aabb.upperBound.y; y += stride) {
        for (float32 x = floorf(aabb.lowerBound.x / stride) * stride; x < aabb.upperBound.x; x += stride) {
            b2Vec2 p(x, y);
            if (shape.TestPoint(identity, p)) {
                
                b2Vec2 pos = p;
                pos.x = (pos.x - _gravityCenter.x) * -1;
                pos.y = (pos.y - _gravityCenter.y) * -1;
                pos.Normalize();
                b2Vec2 force = pos * kCometShootImpulse;
                    
                ZPParticleDef *def = [[ZPParticleDef alloc] init];
                def.initialForce = CGPointMake(force.x, force.y);
                def.type = isStatic ? ZPParticleTypeCore : ZPParticleTypeComet;
                def.state = isStatic ? ZPParticleStateStatic : ZPParticleStateDynamic;
                def.contactBehavior = isExplodable ? ZPParticleContactBehaviorExplosive : ZPParticleContactBehaviorBecomeLiquid;
                def.staticBehavior = ZPParticleStaticBehaviorNone;
                def.gravityBehavior = ZPParticleGravityBehaviorUnlimited;
                
                [self addParticleAt:CGPointMake(x, y) Color:color UserData:def];
            }
        }
    }
}

- (void)addParticleAt:(CGPoint)position Color:(CGRect)color UserData:(ZPParticleDef *)userData {
    NSDictionary *dict = @{kParticlePositionKey: [NSValue valueWithCGPoint:position],
                           kParticleColorKey: [NSValue valueWithCGRect:color],
                           kParticleUserDataKey: userData
    };
    [_particlesToAdd addObject:dict];
}

- (int)createParticleAt:(b2Vec2)position Color:(b2ParticleColor)color UserData:(ZPParticle *)userData {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    
    b2ParticleDef particleDef;
    particleDef.flags = userData->getDefaultFlagsForCurrentType();
    particleDef.position = position;
    particleDef.color = color;
//    particleDef.group = userData->state == ZPParticleStateStatic ? _coreParticleGroup : _cometParticleGroup;
    particleDef.userData = userData;
    return _system->CreateParticle(particleDef);
}

- (void)removeParticleAt:(int)index {
    [_particleIndicesToDestroy addObject:@(index)];
}

- (void)destroyParticleAt:(int)index {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    delete (ZPParticle *)_system->GetUserDataBuffer()[index];
    _system->GetUserDataBuffer()[index] = NULL;
//    _system->DestroyParticle(index);
    _system->DestroyParticle(index, YES);
}

- (void)makeCoreAt:(int)index Force:(CGPoint)force {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    ZPParticleDef *def = [[ZPParticleDef alloc] init];
    
    b2Vec2 pos = _system->GetPositionBuffer()[index];
    b2ParticleColor col = _system->GetColorBuffer()[index];
    
    def.initialForce = force;
    def.state = ZPParticleStateStatic;
    def.type = ZPParticleTypeCore;
    def.gravityBehavior = ZPParticleGravityBehaviorNone;
    def.staticBehavior = ZPParticleStaticBehaviorNone;
    def.contactBehavior = ZPParticleContactBehaviorNone;
    
    [self removeParticleAt:index];
    [self addParticleAt:CGPointMake(pos.x, pos.y) Color:CGRectMake(col.r, col.g, col.b, col.a) UserData:def];
}

- (void)makeLiquidAt:(int)index Force:(CGPoint)force {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    ZPParticleDef *def = [[ZPParticleDef alloc] init];
    
    b2Vec2 pos = _system->GetPositionBuffer()[index];
    b2ParticleColor col = _system->GetColorBuffer()[index];
    
    def.initialForce = force;
    def.state = ZPParticleStateDynamic;
    def.type = ZPParticleTypeCore;
    def.gravityBehavior = ZPParticleGravityBehaviorLimited;
    def.staticBehavior = ZPParticleStaticBehaviorBecomeCore;
    def.contactBehavior = ZPParticleContactBehaviorNone;
    
    [self removeParticleAt:index];
    [self addParticleAt:CGPointMake(pos.x, pos.y) Color:CGRectMake(col.r, col.g, col.b, col.a) UserData:def];
}

@end
