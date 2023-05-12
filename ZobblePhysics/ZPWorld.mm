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

static float kExplosiveImpulse = 1050000;

@implementation ZPWorld {
    CGFloat _rotationStep;
    CGPoint _gravityCenter;
    CGFloat _gravityRadius;
    NSMutableArray *_particlesToAdd;
    NSMutableArray *_particleIndicesToDestroy;
    
    b2ParticleGroup *_staticGroup;
    b2ParticleGroup *_dynamicGroup;
}

- (id)initWithWorldDef:(ZPWorldDef *)def {
    self = [super init];
    
    _rotationStep = def.rotationStep;
    _gravityRadius = def.gravityRadius;
    _gravityCenter = def.center;
    _particleIndicesToDestroy = [NSMutableArray new];
    _particlesToAdd = [NSMutableArray new];
    
    b2World *_world = new b2World(b2Vec2(0, 0));
    _world->SetAllowSleeping(true);
    
    self.world = _world;
    
    b2ParticleSystemDef particleSystemDef;
    
    particleSystemDef.strictContactCheck = def.strictContactCheck;
    particleSystemDef.density = def.density;
    particleSystemDef.gravityScale = def.gravityScale;
    particleSystemDef.radius = def.radius;
    particleSystemDef.maxCount = def.maxCount;
    particleSystemDef.pressureStrength = def.pressureStrength;
    particleSystemDef.dampingStrength = def.dampingStrength;
    particleSystemDef.elasticStrength = def.elasticStrength;
    particleSystemDef.springStrength = def.springStrength;
    particleSystemDef.viscousStrength = def.viscousStrength;
    particleSystemDef.surfaceTensionPressureStrength = def.surfaceTensionPressureStrength;
    particleSystemDef.surfaceTensionNormalStrength = def.surfaceTensionNormalStrength;
    particleSystemDef.repulsiveStrength = def.repulsiveStrength;
    particleSystemDef.powderStrength = def.powderStrength;
    particleSystemDef.ejectionStrength = def.ejectionStrength;
    particleSystemDef.staticPressureStrength = def.staticPressureStrength;
    particleSystemDef.staticPressureRelaxation = def.staticPressureRelaxation;
    particleSystemDef.staticPressureIterations = def.staticPressureIterations;
    particleSystemDef.colorMixingStrength = def.colorMixingStrength;
    particleSystemDef.destroyByAge = def.destroyByAge;
    particleSystemDef.lifetimeGranularity = def.lifetimeGranularity;
    
    b2ParticleSystem *system = _world->CreateParticleSystem(&particleSystemDef);
    self.particleSystem = system;
    
    b2ParticleGroupDef staticGroupDef;
    staticGroupDef.groupFlags = b2_solidParticleGroup | b2_rigidParticleGroup | b2_particleGroupCanBeEmpty;
    _staticGroup = system->CreateParticleGroup(staticGroupDef);
    
    b2ParticleGroupDef dynamicGroupDef;
    dynamicGroupDef.groupFlags = b2_particleGroupCanBeEmpty;
    _dynamicGroup = system->CreateParticleGroup(dynamicGroupDef);
    
    return self;
}

- (void)worldStep:(CFTimeInterval)timeStep
VelocityIterations:(int)velocityIterations
PositionIterations:(int)positionIterations
ParticleIterations:(int)particleIterations {
    
    [self rotateCore];
    
    b2World *_world = (b2World *)self.world;
    _world->Step(timeStep, velocityIterations, positionIterations, particleIterations);
    
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
//    NSLog(@"Total: %d Static: %d(%d) Dynamic: %d(%d) Stuck: %d", _system->GetParticleCount(), staticCount, _staticGroup->GetParticleCount(),  dynamicCount, _dynamicGroup->GetParticleCount(), _system->GetStuckCandidateCount());
    
    [self updateGravity];
    [self processContacts];
    [self checkForStaticParticles];
    [self updateRenderData];
    
    [self createAndRemoveBodies];
}

- (void)rotateCore {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    b2Vec2 *position = _system->GetPositionBuffer();
    
    int count = _staticGroup->GetParticleCount();
    int offset = _staticGroup->GetBufferIndex();
    
    b2Vec2 center = b2Vec2_zero;
    float angleStep = _rotationStep;
    
    for (int i = 0; i < count; i++) {
        b2Vec2 pos = position[i + offset];
        float length = b2Distance(pos, center);
        float angle = atan2(pos.y - center.y, pos.x - center.x);
        
        b2Vec2 newPos = b2Vec2(length * cos(angle + angleStep), length * sin(angle + angleStep));
        position[i + offset] = newPos;
    }
}

- (void)updateGravity {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    
    int particleCount = _system->GetParticleCount();
    b2Vec2 *positionBuffer = _system->GetPositionBuffer();
    void **ud = _system->GetUserDataBuffer();
    
    // Liquids
    for (int i = 0; i < particleCount; i++) {
        ZPParticle *userData = (ZPParticle *)ud[i];
        userData->hasContactWithCore = NO;
        if (userData->gravityScale <= 0) { continue; }
        
        b2Vec2 v = positionBuffer[i];
        b2Vec2 d = b2Vec2(_gravityCenter.x, _gravityCenter.y) - v;
        
        d.Normalize();
        float mass = 10;//_system->GetDensity() * 3.141592 * _system->GetRadius() * _system->GetRadius();
        float force = GRAVITY_FORCE * mass * 2 / d.LengthSquared() * userData->gravityScale;
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
        
        if (userDataA->isDestroying || userDataB->isDestroying) {
            continue;
        }
        
        if (userDataA->state == ZPParticleStateDynamic && userDataB->state == ZPParticleStateStatic) {
            userDataA->hasContactWithCore = YES;
        } else if (userDataB->state == ZPParticleStateDynamic && userDataA->state == ZPParticleStateStatic) {
            userDataB->hasContactWithCore = YES;
        }
        continue;
        if (userDataA->state == ZPParticleStateDynamic &&
            userDataA->becomesLiquidOnContact &&
            userDataB->state == ZPParticleStateStatic) {
            
            [self makeLiquidAt:indexA Force:CGPointMake(0, 0)];
        } else if (userDataB->state == ZPParticleStateDynamic &&
                   userDataB->becomesLiquidOnContact &&
                   userDataA->state == ZPParticleStateStatic) {
            
            [self makeLiquidAt:indexB Force:CGPointMake(0, 0)];
        }
        
        b2Vec2 explosionCenter;
        CGFloat explosionRadius;
        if (userDataA->state == ZPParticleStateDynamic &&
            userDataA->explosionRadius > 0 &&
            userDataB->explosionRadius <= 0) {

            explosionCenter = positionBuffer[indexB];
            explosionRadius = userDataA->explosionRadius;
            [self removeParticleAt:indexA];
        } else if (userDataB->state == ZPParticleStateDynamic &&
                   userDataB->explosionRadius > 0 &&
                   userDataA->explosionRadius <= 0) {

            explosionCenter = positionBuffer[indexA];
            explosionRadius = userDataB->explosionRadius;
            [self removeParticleAt:indexB];
        } else {
            continue;
        }

        for (int i = 0; i < particleCount; i++) {
            b2Vec2 pos = positionBuffer[i];
            float dist = (pos - explosionCenter).Length();
            if (dist < explosionRadius) {
                pos.Normalize();
                b2Vec2 force = pos * kExplosiveImpulse;
                
                [self makeLiquidAt:i Force:CGPointMake(force.x, force.y)];
//                _system->GetColorBuffer()[i] = b2ParticleColor(0, 255, 0, 255);
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
        ZPParticle *userData = (ZPParticle *)ud[i];
        if (userData->isDestroying) {
            continue;
        }
        float velocity = velocityBuffer[i].Length();
        
        if (userData->state == ZPParticleStateDynamic &&
            userData->hasContactWithCore &&
            velocity < userData->freezeVelocityThreshold) {
            
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
        color.Set(col.origin.x, col.origin.y, col.size.width, col.size.height);
        
        ZPParticle *userData = new ZPParticle();
        userData->state = def.state;
        userData->becomesLiquidOnContact = def.becomesLiquidOnContact;
        userData->freezeVelocityThreshold = def.freezeVelocityThreshold;
        userData->gravityScale = def.gravityScale;
        userData->currentFlags = def.currentFlags;
        userData->explosionRadius = def.explosionRadius;
        userData->shootImpulse = def.shootImpulse;
        
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
}

- (void)addParticleWithPosition:(CGPoint)position
                          Color:(CGRect)color
                          Flags:(unsigned int)flags
                       IsStatic:(BOOL)isStatic
                   GravityScale:(CGFloat)gravityScale
        FreezeVelocityThreshold:(CGFloat)freezeVelocityThreshold
         BecomesLiquidOnContact:(BOOL)becomesLiquidOnContact
                ExplosionRadius:(CGFloat)explosionRadius
                   ShootImpulse:(CGFloat)shootImpulse {
    
    b2Vec2 center = b2Vec2(position.x, position.y);
    b2Vec2 pos = center;
    pos.x = (pos.x - _gravityCenter.x) * -1;
    pos.y = (pos.y - _gravityCenter.y) * -1;
    pos.Normalize();
    b2Vec2 force = pos * shootImpulse;
    
    ZPParticleDef *def = [[ZPParticleDef alloc] initWithState:isStatic ? ZPParticleStateStatic : ZPParticleStateDynamic
                                       BecomesLiquidOnContact:becomesLiquidOnContact
                                      FreezeVelocityThreshold:freezeVelocityThreshold
                                                 GravityScale:gravityScale
                                                        Flags:flags
                                              ExplosionRadius:explosionRadius
                                                 ShootImpulse:shootImpulse];
    
    def.initialForce = CGPointMake(force.x, force.y);
    
    [self addParticleAt:position Color:color UserData:def];
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
    
    uint32 resultFlags = 0;
    b2ParticleGroup *group = NULL;
    switch (userData->state) {
        case ZPParticleStateStatic:
            resultFlags = b2_wallParticle | b2_barrierParticle;
            group = _staticGroup;
            break;
        case ZPParticleStateDynamic:
            resultFlags = userData->currentFlags | b2_staticPressureParticle;
            group = _dynamicGroup;
            break;
    }
    
    b2ParticleDef particleDef;
    particleDef.flags = resultFlags;
    particleDef.position = position;
    particleDef.color = color;
    particleDef.userData = userData;
    particleDef.group = group;
    return _system->CreateParticle(particleDef);
}

- (void)removeParticleAt:(int)index {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    ZPParticle *userData = (ZPParticle *)_system->GetUserDataBuffer()[index];
    userData->isDestroying = YES;
    [_particleIndicesToDestroy addObject:@(index)];
}

- (void)destroyParticleAt:(int)index {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    delete (ZPParticle *)_system->GetUserDataBuffer()[index];
    _system->GetUserDataBuffer()[index] = NULL;
    _system->DestroyParticle(index, YES);
}

// TODO: try to avoid deleting and adding particles. try to change their params
- (void)makeCoreAt:(int)index Force:(CGPoint)force {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    ZPParticle *userData = (ZPParticle *)_system->GetUserDataBuffer()[index];

    ZPParticleDef *def = [[ZPParticleDef alloc] initWithState:ZPParticleStateStatic
                                       BecomesLiquidOnContact:userData->becomesLiquidOnContact
                                      FreezeVelocityThreshold:userData->freezeVelocityThreshold
                                                 GravityScale:userData->gravityScale
                                                        Flags:userData->currentFlags
                                              ExplosionRadius:userData->explosionRadius
                                                 ShootImpulse:userData->shootImpulse];
    def.initialForce = force;

    b2Vec2 pos = _system->GetPositionBuffer()[index];
    b2ParticleColor col = _system->GetColorBuffer()[index];

    [self removeParticleAt:index];
    [self addParticleAt:CGPointMake(pos.x, pos.y) Color:CGRectMake(col.r, col.g, col.b, col.a) UserData:def];
}

- (void)makeLiquidAt:(int)index Force:(CGPoint)force {
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    ZPParticle *userData = (ZPParticle *)_system->GetUserDataBuffer()[index];
    
    ZPParticleDef *def = [[ZPParticleDef alloc] initWithState:ZPParticleStateDynamic
                                       BecomesLiquidOnContact:userData->becomesLiquidOnContact
                                      FreezeVelocityThreshold:userData->freezeVelocityThreshold
                                                 GravityScale:userData->gravityScale
                                                        Flags:userData->currentFlags
                                              ExplosionRadius:userData->explosionRadius
                                                 ShootImpulse:userData->shootImpulse];
    
    def.initialForce = force;
    
    b2Vec2 pos = _system->GetPositionBuffer()[index];
    b2ParticleColor col = _system->GetColorBuffer()[index];
    
    [self removeParticleAt:index];
    [self addParticleAt:CGPointMake(pos.x, pos.y) Color:CGRectMake(col.r, col.g, col.b, col.a) UserData:def];
}

@end
