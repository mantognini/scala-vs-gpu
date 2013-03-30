#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/random.h>
#include <thrust/count.h>
#include <utility>
#include <ctime>
#include <cstdlib>
#include <SFML/System.hpp>

std::ostream& operator<<(std::ostream& out, sf::Time const& t);

namespace mc {
    typedef double Real;
    struct Point {
        Real x, y;

        __host__ __device__
        Point(Real x, Real y)
        : x(x)
        , y(y)
        { /* That's it */ }

        __host__ __device__
        Point()
        : x(0)
        , y(0)
        { /* That's it */ }

        friend std::ostream& operator<<(std::ostream& out, Point const& p) {
            return out << "(" << p.x << "; " << p.y << ")";
        }
    };
    typedef thrust::random::uniform_real_distribution<Real> RealDistribution;
    typedef thrust::random::default_random_engine RandomEngine;

    struct RandomPointGenerator {
        // Define two random number generators 
        RandomEngine algoX, algoY;
        RealDistribution dist;

        RandomPointGenerator()
        : algoX(std::rand())
        , algoY(std::rand())
        , dist(0, 1)
        { /* That's it */ }

        __host__ __device__
        Point operator()() {
            return Point(dist(algoX), dist(algoY));
        }
    };

    __host__ __device__
    bool isInside(Point p) {
        return p.x * p.x + p.y * p.y <= 1;
    }

    Real computeRatio(std::size_t pointCount) {
        // Build a random point generator
        RandomPointGenerator generator;

        // Create some random point in the unit square
        thrust::device_vector<Point> points(pointCount);
        thrust::generate(points.begin(), points.end(), generator);

        // TODO remove this loop
        for(int i = 0; i < points.size(); i++) {
            std::cout << "points[" << i << "] = " << points[i]
                      << (isInside(points[i]) ? " is in" : "") << std::endl;
        }

        // Count point inside the circle
        const int pointInCircleCount = thrust::count_if(points.begin(), points.end(), isInside);

        // π/4 = .785398163
        const Real ratio = static_cast<Real>(pointInCircleCount) / static_cast<Real>(pointCount);

        return ratio;
    }

    void stats(std::size_t pointCount) {
        sf::Clock clk;

        const Real r = computeRatio(pointCount);
    
        const sf::Time time = clk.restart();
        std::cout << pointCount << " points; ratio computed in " << time << " : π ~ " << (r * 4) << std::endl;
    }
}

int main(int argc, char** argv)
{
    // Init random numbers
    std::srand(std::time(0));

    // Benchmark with "low" count (from 2^7 to 2^15)
    for (std::size_t c = 128; c <= 32768; c *= 2) { 
        mc::stats(c);
    }

    // Benchmark with "high" count (from 2^16 to 2^22 in ~8 steps)
    for (std::size_t c = 65536; c <= 4194304; c += 524288) {
        mc::stats(c);
    }

    return 0;
}

std::ostream& operator<<(std::ostream& out, sf::Time const& t)
{
    sf::Int64 micros = t.asMicroseconds();
    return out << micros << "µs";
}
