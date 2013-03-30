/*
 * infosv
 * sept 2012
 * Marco Antognini
 */

#include "Uniform.hpp"


template <>
Vec2d uniform<Vec2d>(Vec2d topLeft, Vec2d bottomRight)
{
    return { uniform(topLeft.x, bottomRight.x), uniform(topLeft.y, bottomRight.y) };
}
