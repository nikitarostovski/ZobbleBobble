//
//  ZPRigidBody.mm
//  ZobblePhysics
//
//  Created by Rost on 20.11.2022.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "ZPRigidBody.h"
#import "ZPWorld.h"
#import "Box2D.h"

@implementation ZPRigidBody {
    b2Body * _body;
}

- (id)initWithEdge:(CGPoint)p1 To:(CGPoint)p2 IsDynamic:(BOOL)isDynamic Position:(CGPoint)position Density:(float)density Friction:(float)friction Restitution:(float)restitution Category:(int)category AtWorld:(ZPWorld *)world {
    
    b2Vec2 point1 = *new b2Vec2(p1.x / SCALE_RATIO, p1.y / SCALE_RATIO);
    b2Vec2 point2 = *new b2Vec2(p2.x / SCALE_RATIO, p2.y / SCALE_RATIO);
    b2EdgeShape shape;
    shape.Set(point1, point2);
    
    b2BodyType type = isDynamic ? b2_dynamicBody : b2_staticBody;
    
    self = [self initWithShape:&shape Type:type Position:position Density:density Friction:friction Restitution:restitution Category:category World:world];
    
    return self;
}

- (id)initWithPolygon:(NSArray<NSValue *> *)points IsDynamic:(BOOL)isDynamic Position:(CGPoint)position Density:(float)density Friction:(float)friction Restitution:(float)restitution Category:(int)category AtWorld:(ZPWorld *)world {
    b2Vec2 *pts = new b2Vec2[points.count];
    for (int i = 0; i < points.count; i++) {
        NSValue *v = points[i];
        CGPoint pt = [v CGPointValue];
        b2Vec2 p = *new b2Vec2(pt.x / SCALE_RATIO, pt.y / SCALE_RATIO);
        pts[i] = p;
    }
    b2PolygonShape boxShape;
    boxShape.Set(pts, (int32)points.count);
    
    b2BodyType type = isDynamic ? b2_dynamicBody : b2_staticBody;
    
    self = [self initWithShape:&boxShape Type:type Position:position Density:density Friction:friction Restitution:restitution Category:category World:world];
    
    return self;
}

- (id)initWithRadius:(float)radius IsDynamic:(BOOL)isDynamic Position:(CGPoint)position Density:(float)density Friction:(float)friction Restitution:(float)restitution Category:(int)category AtWorld:(ZPWorld *)world {
    b2CircleShape shape;
    shape.m_radius = radius / SCALE_RATIO;
    
    b2BodyType type = isDynamic ? b2_dynamicBody : b2_staticBody;
    
    self = [self initWithShape:&shape Type:type Position:position Density:density Friction:friction Restitution:restitution Category:category World:world];
    
    return self;
}

- (id)initWithShape:(b2Shape *)shape Type:(b2BodyType)type Position:(CGPoint)position Density:(float)density Friction:(float)friction Restitution:(float)restitution Category:(int)category World:(ZPWorld *)world {
    self.isDestroying = false;
    self.world = world;
    self.category = category;
    self = [super init];
    
    b2BodyDef bodyDef;
    bodyDef.type = type;
    bodyDef.position.Set(position.x / SCALE_RATIO, position.y / SCALE_RATIO);
    bodyDef.angle = 0;
    
    b2World *_world = (b2World *)world.world;
    b2Body *body = _world->CreateBody(&bodyDef);
    
    body->SetUserData((__bridge void *) self);
    
    b2FixtureDef fixtureDef;
    fixtureDef.shape = shape;
    fixtureDef.density = density;
    fixtureDef.restitution = restitution;
    fixtureDef.friction = friction;
    body->CreateFixture(&fixtureDef);
    
    _body = body;
    
    [world.bodies addObject:self];
    
    return self;
}

- (void)stepAtWorld:(ZPWorld *)world {
    if (_body == NULL) { return; }
    
    b2Vec2 p = _body->GetPosition();
    self.position = CGPointMake(p.x * SCALE_RATIO, p.y * SCALE_RATIO);
    self.angle = _body->GetAngle();
    
    b2Vec2 d = p - b2Vec2_zero;
    d.Normalize();
    float force = GRAVITY_FORCE * _body->GetMass() * 2 / d.LengthSquared();
    
    _body->ApplyForce(d * -force, p, true);
    
    if (self.isDestroying) {
        _body->GetWorld()->DestroyBody(_body);
        _body = nil;
    }
}

- (void)destroy {
    self.isDestroying = true;
}

@end
