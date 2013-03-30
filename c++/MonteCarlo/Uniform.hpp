/*
 * infosv
 * sept 2012
 * Marco Antognini
 */

#ifndef INFOSV_RANDOM_UNIFORM_HPP
#define INFOSV_RANDOM_UNIFORM_HPP

#include "../Utility/Vec2d.hpp"

#include <type_traits>
#include <random>

/*!
 * @brief Randomly generate a number on a uniform distribution
 *
 * @param min lower bound
 * @param max upper bound
 * @return a random number fitting the uniform distribution
 */
template <typename T>
T uniform(T min, T max)
{
    static std::default_random_engine algo;
    
    static bool initialise = true;
    if (initialise) {
        initialise = false;
        std::random_device rd;
        algo.seed(rd());
    }

    typedef typename std::is_integral<T> condition;
    typedef typename std::uniform_int_distribution<T> integer_dist;
    typedef typename std::uniform_real_distribution<T> real_dist;

    typedef typename std::conditional<condition::value,
                                      integer_dist,
                                      real_dist>::type distribution_type;

    distribution_type dist(min, max);

    return dist(algo);
}

template <>
Vec2d uniform<Vec2d>(Vec2d topLeft, Vec2d bottomRight);

#endif // INFOSV_RANDOM_UNIFORM_HPP

