    
#include <iostream>
#include <random>
#include <functional>
#include <utility>
#include <vector>
#include <algorithm>
#include <sstream>
#include "stats.hpp"

namespace mc {
    
    typedef double Real;
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

        Real sum = 0.0;
        // Create some random point in the unit square and see if they are in the circle
        for (std::size_t i = 0; i < pointCount; ++i) {
            if (isInside(randomPoint())) {
                ++sum;
            }
        }
        const Real pi = sum / pointCount * 4;

        return pi;
    }
}

struct MonteCarlo
{
    MonteCarlo(std::size_t pointCount)
    : pointCount(pointCount)
    { /* - */ }

    double operator()() const {
        return mc::computePi(pointCount);
    }

    std::string csvdescription() const {
        std::stringstream ss;
        ss << pointCount;
        return ss.str();
    }

    std::size_t pointCount;
};

int main(int argc, const char * argv[])
{
    // Benchmark with "low" count (from 2^7 to 2^15)
    for (std::size_t c = 128; c <= 32768; c *= 2) {
        // Do 100 measurements for low point count
        stats<MonteCarlo, double>(MonteCarlo(c), 100);
    }

    // Benchmark with "high" count (from 2^16 to 2^22 in ~8 steps)
    for (std::size_t c = 65536; c <= 4194304; c += 524288) {
        // Do 10 measurements for each high point count
        stats<MonteCarlo, double>(MonteCarlo(c), 10);
    }

    return 0;
}

