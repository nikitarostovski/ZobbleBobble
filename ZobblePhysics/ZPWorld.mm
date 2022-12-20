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
#import "ZPContactListener.h"

#import "ZPSoftBody.h"

@implementation ZPWorld {
    ZPContactListener *_contactListener;
}

- (id)initWithGravity:(CGPoint)gravity ParticleRadius:(CGFloat)radius {
    self = [super init];
    
    self.bodies = [NSMutableArray new];
    b2World *_world = new b2World(b2Vec2(gravity.x, gravity.y));
    self.world = _world;
    
    b2ParticleSystemDef particleSystemDef;
    particleSystemDef.radius = radius / SCALE_RATIO;
    particleSystemDef.dampingStrength = 1;
    particleSystemDef.gravityScale = 1;
    particleSystemDef.density = 1;
    particleSystemDef.viscousStrength = 0.95;
    
    b2ParticleSystem *system = _world->CreateParticleSystem(&particleSystemDef);
    system->SetStaticPressureIterations(8);
    self.particleSystem = system;
    
    
    
    return self;
}

- (void)worldStep:(CFTimeInterval)timeStep velocityIterations:(int)velocityIterations positionIterations:(int)positionIterations {
    b2World *_world = (b2World *)self.world;
    _world->Step(timeStep, velocityIterations, positionIterations, 3);
    
    
    b2ParticleSystem *_system = (b2ParticleSystem *)self.particleSystem;
    
    b2ParticleGroup *const *groupBuffer = _system->GetGroupBuffer();
    
    int bodyContactCount = _system->GetBodyContactCount();
    const b2ParticleBodyContact *bodyContacts = _system->GetBodyContacts();
    
    for (int i = 0; i < bodyContactCount; i++) {
        b2ParticleBodyContact contact = bodyContacts[i];
        
        int index = contact.index;
        b2Body *body = contact.body;
        
        b2ParticleGroup *groupA = groupBuffer[index];
        ZPSoftBody *bodyA = (__bridge ZPSoftBody *)groupA->GetUserData();
        ZPBody *bodyB = (__bridge ZPBody *)body->GetUserData();
        
        if (bodyA.category == CAT_CORE && bodyB.category == CAT_COMET) {
            bodyB.onContact(bodyA);
        } else if (bodyA.category == CAT_COMET && bodyB.category == CAT_CORE) {
            bodyA.onContact(bodyB);
        }
    }
    
    int contactCount = _system->GetContactCount();
    const b2ParticleContact *contactBuffer = _system->GetContacts();
    
    for (int i = 0; i < contactCount; i++) {
        b2ParticleContact contact = contactBuffer[i];
        
        int indexA = contact.GetIndexA();
        int indexB = contact.GetIndexB();
        
        b2ParticleGroup *groupA = groupBuffer[indexA];
        b2ParticleGroup *groupB = groupBuffer[indexB];
        
        ZPSoftBody *bodyA = (__bridge ZPSoftBody *)groupA->GetUserData();
        ZPSoftBody *bodyB = (__bridge ZPSoftBody *)groupB->GetUserData();
        
        if (bodyA.category == CAT_CORE && bodyB.category == CAT_COMET) {
            bodyB.onContact(bodyA);
        } else if (bodyA.category == CAT_COMET && bodyB.category == CAT_CORE) {
            bodyA.onContact(bodyB);
        }
    }
    
    
    
//    std::vector<ZPContact>::iterator pos;
//    for(pos = _contactListener->_contacts.begin();
//        pos != _contactListener->_contacts.end(); ++pos) {
//        ZPContact contact = *pos;
//
//        b2Fixture *fixtureA = contact.fixtureA;
//        b2Fixture *fixtureB = contact.fixtureB;
//        b2ParticleGroup *particleGroup = contact.particleGroup;
//
//        if (fixtureA == nil) {
//            continue;
//        }
//
//        b2Body *bA = fixtureA->GetBody();
//
//        ZPBody *bodyA = (__bridge ZPBody *)bA->GetUserData();
//        ZPBody *bodyB;
//
//        if (fixtureB != nil) {
//            b2Body *bB = fixtureB->GetBody();
//            bodyB = (__bridge ZPBody *)bB->GetUserData();
//        } else if (particleGroup != nil) {
//            bodyB = (__bridge ZPBody *)particleGroup->GetUserData();
//        } else {
//            continue;
//        }
//
//        int categoryA = bodyA.category;
//        int categoryB = bodyB.category;
//
//        if (categoryA == CAT_CORE && categoryB == CAT_COMET) {
//            bodyB.onContact(bodyA);
////            _contactListener->_contacts.erase(pos);
//        } else if (categoryA == CAT_COMET && categoryB == CAT_CORE) {
//            bodyA.onContact(bodyB);
////            _contactListener->_contacts.erase(pos);
//        }
//    }

    NSMutableArray *toRemove = [NSMutableArray new];
    for (ZPBody *body in self.bodies) {
        [body stepAtWorld:self];
        BOOL needToRemove = [body isDestroying];
        if (needToRemove) {
            [toRemove addObject: body];
        }
    }
    for (ZPBody *body in toRemove) {
        [self.bodies removeObject:body];
    }
}

@end
