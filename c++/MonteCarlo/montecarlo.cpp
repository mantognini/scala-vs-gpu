    
#include <iostream>
#include <SFML/System.hpp>
#include <random>
#include <functional>
#include <utility>
#include <vector>
#include <algorithm>

std::ostream& operator<<(std::ostream& out, sf::Time const& t);

namespace mc {
    
    typedef double Real;
    typedef std::pair<Real, Real> Point;
    typedef std::uniform_real_distribution<Real> RealDistribution;
    typedef std::default_random_engine RandomEngine;

    Real computeRatio(std::size_t pointCount) {
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

        return ratio;
    }

    void stats(std::size_t pointCount) {
        sf::Clock clk;

        const Real r = computeRatio(pointCount);
    
        const sf::Time time = clk.restart();
        std::cout << "ratio computed in " << time << " : π ~ " << (r * 4) << std::endl;
    }
}

int main(int argc, const char * argv[])
{
    mc::stats(128);

    return 0;
}

std::ostream& operator<<(std::ostream& out, sf::Time const& t)
{
    sf::Int64 micros = t.asMicroseconds();
    return out << micros << "µs";
}
