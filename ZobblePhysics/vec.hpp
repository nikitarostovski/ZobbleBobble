//
//  vec.h
//  ZobbleBobble
//
//  Created by Никита Ростовский on 08.10.2023.
//


struct Vec2
{
    float x;
    float y;
    
    Vec2(float new_x, float new_y)
    {
        x = new_x;
        y = new_y;
    }
    
    inline Vec2 operator+(Vec2 a) {
        return {a.x+x,a.y+y};
    }
    
    inline Vec2 operator-(Vec2 a) {
//        return {a.x-x,a.y-y};
        return {x-a.x,y-a.y};
    }
    
    
};

struct IVec2
{
  int x;
  int y;
};
