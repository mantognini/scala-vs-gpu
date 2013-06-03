    
#include <iostream>
#include <random>
#include <functional>
#include <utility>
#include <vector>
#include <algorithm>
#include <sstream>
#include "stats.hpp"

typedef double Real;

namespace mc {

    typedef std::pair<Real, Real> Point;
    typedef std::uniform_real_distribution<Real> RealDistribution;
    typedef std::default_random_engine RandomEngine;

    Real computePi(std::size_t pointCount) {
        // Define two random number generators gX and gY
        RandomEngine algoX, algoY;
        std::random_device rd;
        algoX.seed(rd());
        algoY.seed(rd());
        RealDistribution dist(0, 1);
        auto gX = std::bind(dist, algoX);
        auto gY = std::bind(dist, algoY);

        const auto randomPoint = [&]()->Point {
            return { gX(), gY() };
        };

        const auto isInside = [](Point p)->bool {
            return p.first * p.first + p.second * p.second <= 1;
        };

        // Create some random point in the unit square
        std::vector<Point> points(pointCount);
        std::generate(points.begin(), points.end(), randomPoint);

        // Count point inside the circle
        const auto pointInCircleCount = std::count_if(points.begin(), points.end(), isInside);

        // π/4 = .785398163
        const Real ratio = static_cast<Real>(pointInCircleCount) / static_cast<Real>(pointCount);

        return ratio * 4.0;
    }
}

struct MonteCarlo
{
    MonteCarlo(std::size_t pointCount)
    : pointCount(pointCount)
    { /* - */ }

    Real operator()() const {
        return mc::computePi(pointCount);
    }

    std::string csvdescription() const {
        std::stringstream ss;
        ss << "C++#1," << pointCount;
        return ss.str();
    }

    std::size_t pointCount;
};

int main(int argc, const char * argv[])
{
    // Benchmark count from 2^7 to 2^22
    for (std::size_t c = 128; c <= 4194304; c *= 2) {
        // Do 100 measurements for low point count
        stats<MonteCarlo, Real>(MonteCarlo(c), 100);
    }

    return 0;
}

