//
//  ZPWorldDef.h
//  ZobblePhysics
//
//  Created by Rost on 06.02.2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef unsigned int uint32;
typedef int int32;
typedef float float32;

@interface ZPWorldDef : NSObject
/// Enable strict Particle/Body contact check.
/// See SetStrictContactCheck for details.
@property bool strictContactCheck;

/// Set the particle density.
/// See SetDensity for details.
@property float32 density;

/// Change the particle gravity scale. Adjusts the effect of the global
/// gravity vector on particles. Default value is 1.0f.
@property float32 gravityScale;

/// Particles behave as circles with this radius. In Box2D units.
@property float32 radius;

/// Set the maximum number of particles.
/// By default, there is no maximum. The particle buffers can continue to
/// grow while b2World's block allocator still has memory.
/// See SetMaxParticleCount for details.
@property int32 maxCount;

/// Increases pressure in response to compression
/// Smaller values allow more compression
@property float32 pressureStrength;

/// Reduces velocity along the collision normal
/// Smaller value reduces less
@property float32 dampingStrength;

/// Restores shape of elastic particle groups
/// Larger values increase elastic particle velocity
@property float32 elasticStrength;

/// Restores length of spring particle groups
/// Larger values increase spring particle velocity
@property float32 springStrength;

/// Reduces relative velocity of viscous particles
/// Larger values slow down viscous particles more
@property float32 viscousStrength;

/// Produces pressure on tensile particles
/// 0~0.2. Larger values increase the amount of surface tension.
@property float32 surfaceTensionPressureStrength;

/// Smoothes outline of tensile particles
/// 0~0.2. Larger values result in rounder, smoother, water-drop-like
/// clusters of particles.
@property float32 surfaceTensionNormalStrength;

/// Produces additional pressure on repulsive particles
/// Larger values repulse more
/// Negative values mean attraction. The range where particles behave
/// stably is about -0.2 to 2.0.
@property float32 repulsiveStrength;

/// Produces repulsion between powder particles
/// Larger values repulse more
@property float32 powderStrength;

/// Pushes particles out of solid particle group
/// Larger values repulse more
@property float32 ejectionStrength;

/// Produces static pressure
/// Larger values increase the pressure on neighboring partilces
/// For a description of static pressure, see
/// http://en.wikipedia.org/wiki/Static_pressure#Static_pressure_in_fluid_dynamics
@property float32 staticPressureStrength;

/// Reduces instability in static pressure calculation
/// Larger values make stabilize static pressure with fewer iterations
@property float32 staticPressureRelaxation;

/// Computes static pressure more precisely
/// See SetStaticPressureIterations for details
@property int32 staticPressureIterations;

/// Determines how fast colors are mixed
/// 1.0f ==> mixed immediately
/// 0.5f ==> mixed half way each simulation step (see b2World::Step())
@property float32 colorMixingStrength;

/// Whether to destroy particles by age when no more particles can be
/// created.  See #b2ParticleSystem::SetDestructionByAge() for
/// more information.
@property bool destroyByAge;

/// Granularity of particle lifetimes in seconds.  By default this is
/// set to (1.0f / 60.0f) seconds.  b2ParticleSystem uses a 32-bit signed
/// value to track particle lifetimes so the maximum lifetime of a
/// particle is (2^32 - 1) / (1.0f / lifetimeGranularity) seconds.
/// With the value set to 1/60 the maximum lifetime or age of a particle is
/// 2.27 years.
@property float32 lifetimeGranularity;

@property CGPoint center;
@property CGFloat gravityRadius;

@property CGFloat rotationStep;

- (id)init;

@end

NS_ASSUME_NONNULL_END
