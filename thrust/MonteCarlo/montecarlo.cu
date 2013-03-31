#include <thrust/device_vector.h>
#include <thrust/random.h>
#include <thrust/count.h>
#include <ctime>
#include <cstdlib>
#include <sstream>

#include "stats.hpp"

namespace mc {
    typedef double Real;
    typedef thrust::pair<Real, Real> Point;
    // typedef thrust::host_vector<Point> Points;
    typedef thrust::device_vector<Point> Points;
    typedef thrust::random::uniform_real_distribution<Real> RealDistribution;
    typedef thrust::random::default_random_engine RandomEngine;

    std::ostream& operator<<(std::ostream& out, Point const& p)
    {
        return out << "(" << p.first << "; " << p.second << ")";
    }
    
    struct RandomPointGenerator {
        unsigned int seedX, seedY;

        RandomPointGenerator(unsigned int seedX, unsigned int seedY)
        : seedX(seedX)
        , seedY(seedY)
        { /* That's it */ }

        __host__ __device__
        Point operator()(std::size_t n)
        {
            RandomEngine algoX(seedX), algoY(seedY);
            RealDistribution dist(0, 1);
            algoX.discard(n);
            algoY.discard(n);
            return Point(dist(algoX), dist(algoY));
        }
    };

    struct IsInside {
        __host__ __device__
        bool operator()(Point const& p)
        {
            return p.first * p.first + p.second * p.second <= 1;
        }
    };

    Real computePi(std::size_t pointCount)
    {
        // Create some random point in the unit square
        RandomPointGenerator generator(std::rand(), std::rand());
        Points points(pointCount);
        thrust::counting_iterator<std::size_t> index_sequence_begin(0);
        thrust::transform(index_sequence_begin,
                          index_sequence_begin + pointCount,
                          points.begin(),
                          generator);

        // Count point inside the circle
        const int pointInCircleCount = thrust::count_if(points.begin(), points.end(), IsInside());

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


int main(int argc, char** argv)
{
    // Init random numbers
    std::srand(std::time(0));

    // Warmup !
    stats<MonteCarlo, double>(MonteCarlo(128));

    // Benchmark with "low" count (from 2^7 to 2^15)
    for (std::size_t c = 128; c <= 32768; c *= 2) { 
        stats<MonteCarlo, double>(MonteCarlo(c), 100);
    }

    // Benchmark with "high" count (from 2^16 to 2^22 in ~8 steps)
    for (std::size_t c = 65536; c <= 4194304; c += 524288) {
        stats<MonteCarlo, double>(MonteCarlo(c), 10);
    }

    return 0;
}

