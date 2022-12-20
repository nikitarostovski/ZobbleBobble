//
//  ZPContact.h
//  ZobbleBobble
//
//  Created by Rost on 17.12.2022.
//

#import "Box2D.h"
#import "ZPBody.h"

struct ZPContact {
    b2Fixture *fixtureA;
    b2Fixture *fixtureB;
    b2ParticleGroup *particleGroup;

    bool operator==(const ZPContact& other) const
    {
        return (fixtureA == other.fixtureA) && (fixtureB == other.fixtureB) && (particleGroup == other.particleGroup);
    }
};

//class ZPContact {
//    b2Body *bodyA;
//    b2Body *bodyB;
//    b2ParticleGroup *particleGroup;
//
//public:
//
//    ZPContact(b2Fixture *a, b2Fixture *b) {
//        bodyA = a->GetBody();
//        bodyB = b->GetBody();
//        particleGroup = nil;
//    }
//
//    ZPContact(b2Fixture *a, b2ParticleGroup *p) {
//        bodyA = a->GetBody();
//        bodyB = nil;
//        particleGroup = p;
//    }
//
//    void *getBodyA() {
//        return bodyA->GetUserData();
//    }
//
//    void *getBodyB() {
//        if (particleGroup != nil) {
//            return particleGroup->GetUserData();
//        } else if (bodyB != nil) {
//            return bodyB->GetUserData();
//        }
//        return nil;
//    }
//
//    bool isValid() {
//        return (bodyA != nil && (bodyB != nil || particleGroup != nil));
//    }
//
//    bool operator==(const ZPContact other) const
//    {
//        return (bodyA == other.bodyA) && (bodyB == other.bodyB) && (particleGroup == other.particleGroup);
//    }
//};
