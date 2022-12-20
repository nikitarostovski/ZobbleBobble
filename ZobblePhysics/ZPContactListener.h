//
//  ZPContactListener.h
//  ZobbleBobble
//
//  Created by Rost on 17.12.2022.
//

#import "Box2D.h"
#import <vector>
#import <algorithm>
#import "ZPContact.h"

class ZPContactListener : public b2ContactListener {
    int i;
public:
    std::vector<ZPContact>_contacts;
    
    ZPContactListener();
    ~ZPContactListener();
    
    virtual void BeginContact(b2Contact* contact);
    virtual void EndContact(b2Contact* contact);
    virtual void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);
    virtual void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse);
    virtual void BeginContact(b2ParticleSystem* particleSystem, b2ParticleBodyContact* particleBodyContact);
    virtual void EndContact(b2Fixture* fixture, b2ParticleSystem* particleSystem, int32 index);
    virtual void BeginContact(b2ParticleSystem* particleSystem, b2ParticleContact* particleContact);
    virtual void EndContact(b2ParticleSystem* particleSystem, int32 indexA, int32 indexB);
};
