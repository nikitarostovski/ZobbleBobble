//
//  physic_object.h
//  ZobbleBobble
//
//  Created by Никита Ростовский on 08.10.2023.
//
#pragma once
#include "collision_grid.hpp"
#include "utils.hpp"
#include "math.hpp"
#include <simd/SIMD.h>

struct PhysicObject
{
    // Verlet
    Vec2 position      = {0.0f, 0.0f};
    Vec2 last_position = {0.0f, 0.0f};
    Vec2 acceleration  = {0.0f, 0.0f};
//    simd::uchar4 color;

    PhysicObject() = default;
    
    explicit
    PhysicObject(Vec2 position_, simd::uchar4 color_)
        : position(position_)
//        , color(color_)
        , last_position(position_)
    {}

    void setPosition(Vec2 pos)
    {
        position      = pos;
        last_position = pos;
    }

    void update(float dt)
    {
        auto c = 1.0f; // 40.0f
        const Vec2 last_update_move = Vec2(position.x - last_position.x, position.y - last_position.y);
        
        last_position = position;
        position.x = position.x + last_update_move.x + (acceleration.x - last_update_move.x * c) * (dt * dt);
        position.y = position.y + last_update_move.y + (acceleration.y - last_update_move.y * c) * (dt * dt);
        acceleration = {0.0f, 0.0f};
    }

    void stop()
    {
        last_position = position;
    }

    void slowdown(float ratio)
    {
        last_position.x = last_position.x + ratio * (position.x - last_position.x);
        last_position.y = last_position.y + ratio * (position.y - last_position.y);
    }

    [[nodiscard]]
    float getSpeed() const
    {
        return sqrt(pow(position.x - last_position.x, 2) + pow(position.y - last_position.y, 2));
    }

    [[nodiscard]]
    Vec2 getVelocity() const
    {
        return Vec2(position.x - last_position.x, position.y - last_position.y);
    }

    void addVelocity(Vec2 v)
    {
        last_position.x = last_position.x - v.x;
        last_position.y = last_position.y - v.y;
    }

    void setPositionSameSpeed(Vec2 new_position)
    {
        const Vec2 to_last = Vec2(last_position.x - position.x, last_position.y - position.y);
        position = new_position;
        last_position = Vec2(position.x + to_last.x, position.y + to_last.y);
    }

    void move(Vec2 v)
    {
        position.x += v.x;
        position.y += v.y;
    }
};
