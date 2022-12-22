//
//  ZPBody.mm
//  ZobblePhysics
//
//  Created by Rost on 19.11.2022.
//

#import "ZPBody.h"
#import <UIKit/UIKit.h>
#import "Constants.h"
#import "ZPBody.h"
#import "ZPWorld.h"
#import "Box2D.h"

@implementation ZPBody

- (id)initWithPolygon:(NSArray<NSValue *> *)points IsDynamic:(BOOL)isDynamic Position:(CGPoint)position Density:(float)density Friction:(float)friction Restitution:(float)restitution Category:(int)category AtWorld:(ZPWorld *)world {
    b2Vec2 *pts = new b2Vec2[points.count];
    for (int i = 0; i < points.count; i++) {
        NSValue *v = points[i];
        CGPoint pt = [v CGPointValue];
        b2Vec2 p = *new b2Vec2(pt.x, pt.y);
        pts[i] = p;
    }
    b2PolygonShape shape;
    shape.Set(pts, (int32)points.count);
    
    b2BodyType type = isDynamic ? b2_dynamicBody : b2_staticBody;
    
    self.isRemoving = NO;
    self.polygon = points;
    self = [super init];
    
    b2BodyDef bodyDef;
    bodyDef.type = type;
    bodyDef.position.Set(position.x, position.y);
    bodyDef.angle = 0;
    
    b2World *_world = (b2World *)world.world;
    b2Body *body = _world->CreateBody(&bodyDef);
    
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = density;
    fixtureDef.restitution = restitution;
    fixtureDef.friction = friction;
    body->CreateFixture(&fixtureDef);
    
    self.body = body;
    
    return self;
}

@end
