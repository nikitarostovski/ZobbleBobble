//
//  ZPSoftBody.mm
//  ZobblePhysics
//
//  Created by Rost on 20.11.2022.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "ZPSoftBody.h"
#import "ZPWorld.h"
#import "Box2D.h"

@implementation ZPSoftBody {
    b2ParticleGroup *_particleGroup;
}

- (id)initWithPolygon:(NSArray<NSValue *> *)polygon Position:(CGPoint)position Color:(CGRect)color AtWorld:(ZPWorld *)world {
    self = [super init];
    
    self.positions = [NSMutableArray new];
    self.colors = [NSMutableArray new];
    
    b2Vec2 *pts = new b2Vec2[polygon.count];
    for (int i = 0; i < polygon.count; i++) {
        NSValue *v = polygon[i];
        CGPoint pt = [v CGPointValue];
        b2Vec2 p = *new b2Vec2(pt.x / SCALE_RATIO, pt.y / SCALE_RATIO);
        pts[i] = p;
    }
    b2PolygonShape shape;
    shape.Set(pts, (int32)polygon.count);
    
    
    
    b2ParticleGroupDef particleGroupDef;
    particleGroupDef.flags = b2_tensileParticle;
    particleGroupDef.position.Set(position.x / SCALE_RATIO, position.y / SCALE_RATIO);
    particleGroupDef.shape = &shape;
    particleGroupDef.strength = 1;
    particleGroupDef.color = b2ParticleColor(color.origin.x, color.origin.y, color.size.width, 255);

    b2ParticleSystem *_particleSystem = (b2ParticleSystem *)world.particleSystem;
    _particleGroup = _particleSystem->CreateParticleGroup(particleGroupDef);
    
    [world.bodies addObject:self];
    
    return self;
}

- (void)stepAtWorld:(ZPWorld *)world {
    b2ParticleSystem *_system = (b2ParticleSystem *)world.particleSystem;
    int particleCount = _system->GetParticleCount();
    b2Vec2 *positionBuffer = _system->GetPositionBuffer();
    b2ParticleColor *colorBuffer = _system->GetColorBuffer();

    NSMutableArray *points = [NSMutableArray new];
    NSMutableArray *colors = [NSMutableArray new];
    for (int i = 0; i < particleCount; i++) {
        if (!_particleGroup->ContainsParticle(i)) {
            continue;
        }
        b2Vec2 v = positionBuffer[i];
        b2ParticleColor col = colorBuffer[i];
        
        CGPoint p = CGPointMake((v.x) * SCALE_RATIO, v.y * SCALE_RATIO);
        [points addObject:[NSValue valueWithCGPoint:p]];
        CGRect c = CGRectMake(col.r / 255.0, col.g / 255.0, col.b / 255.0, col.a / 255.0);
        [colors addObject:[NSValue valueWithCGRect:c]];
    }
    self.positions = points;
    self.colors = colors;
}

@end
