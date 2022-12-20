//
//  ZPContactListener.m
//  ZobblePhysics
//
//  Created by Rost on 17.12.2022.
//

#import "ZPContactListener.h"

ZPContactListener::ZPContactListener() : _contacts() {
}

ZPContactListener::~ZPContactListener() {
}

void ZPContactListener::BeginContact(b2Contact* contact) {
    // We need to copy out the data because the b2Contact passed in
    // is reused.
    ZPContact myContact = { contact->GetFixtureA(), contact->GetFixtureB(), nil };
    _contacts.push_back(myContact);
}

void ZPContactListener::EndContact(b2Contact* contact) {
    ZPContact myContact = { contact->GetFixtureA(), contact->GetFixtureB(), nil };
    std::vector<ZPContact>::iterator pos;
    pos = std::find(_contacts.begin(), _contacts.end(), myContact);
    if (pos != _contacts.end()) {
        _contacts.erase(pos);
    }
}

void ZPContactListener::PreSolve(b2Contact* contact, const b2Manifold* oldManifold) {
    
}

void ZPContactListener::PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {
    
}

void ZPContactListener::BeginContact(b2ParticleSystem* particleSystem, b2ParticleBodyContact* particleBodyContact) {
    
    b2ParticleGroup *group = nil;
    for (int i = 0; i < particleSystem->GetParticleGroupCount(); i++) {
        b2ParticleGroup *g = particleSystem->GetGroupBuffer()[i];
        if (g->ContainsParticle(particleBodyContact->index)) {
            group = g;
            break;
        }
    }
    ZPContact myContact = { particleBodyContact->fixture, nil, group };
    _contacts.push_back(myContact);
}

void ZPContactListener::EndContact(b2Fixture* fixture, b2ParticleSystem* particleSystem, int32 index) {
    b2ParticleGroup *group = nil;
    for (int i = 0; i < particleSystem->GetParticleGroupCount(); i++) {
        b2ParticleGroup *g = particleSystem->GetGroupBuffer()[i];
        if (g->ContainsParticle(index)) {
            group = g;
            break;
        }
    }
    
    ZPContact myContact = { fixture, nil, group };
    std::vector<ZPContact>::iterator pos;
    
    pos = std::find(_contacts.begin(), _contacts.end(), myContact);
    if (pos != _contacts.end()) {
        _contacts.erase(pos);
    }
}

void ZPContactListener::BeginContact(b2ParticleSystem *particleSystem, b2ParticleContact *particleContact) {
    int32 indexA = particleContact->GetIndexA();
    int32 indexB = particleContact->GetIndexB();
    
    
    
}

void ZPContactListener::EndContact(b2ParticleSystem *particleSystem, int32 indexA, int32 indexB) {
    
}
