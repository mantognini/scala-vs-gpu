// Implementation inspired from
// https://github.com/thrust/thrust/blob/master/examples/monte_carlo.cu

#include <thrust/random.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/functional.h>
#include <thrust/transform_reduce.h>

#include <iostream>
#include <sstream>
#include <ctime>
#include <cstdlib>

#include "stats.hpp"

typedef float Real;

struct MonteCarlo : public thrust::unary_function<std::size_t, Real>
{
    // Note : N must divide pointCount
    MonteCarlo(std::size_t pointCount, std::size_t N)
    : pointCount(pointCount), N(N), seedX(std::rand()), seedY(std::rand())
    { /* That's it */ }

    // This overload approximates π with N points on GPU
    __host__ __device__
    Real operator()(std::size_t threadId)
    {
        Real sum = 0;

        // seed a random number generator
        thrust::default_random_engine rngX(seedX);
        rngX.discard(N * threadId);
        thrust::default_random_engine rngY(seedY);
        rngY.discard(N * threadId);

        // create a mapping from random numbers to [0,1)
        thrust::uniform_real_distribution<Real> dist(0,1);

        // take N samples in a quarter circle
        for(unsigned int i = 0; i < N; ++i) {
            // draw a sample from the unit square
            const Real x = dist(rngX);
            const Real y = dist(rngY);

            // add 1.0 if (x, y) is inside the quarter circle
            if(x * x + y * y <= 1.0)
                sum += 1.0;
        }

        // multiply by 4 to get the area of the whole circle
        sum *= 4.0f;

        // divide by N
        return sum / N;
    }

    // This overload approximate π by dispatching computation onto the GPU
    Real operator()() const {
        // Reset seeds
        seedX = std::rand();
        seedY = std::rand();

        const std::size_t M = pointCount / N;

        Real estimate = thrust::transform_reduce(thrust::counting_iterator<std::size_t>(0),
                                                 thrust::counting_iterator<std::size_t>(M),
                                                 *this, // Apply op()(std::size_t)
                                                 0.0f,
                                                 thrust::plus<Real>());
        estimate /= M;
        return estimate;
    }

    std::string csvdescription() const {
        std::stringstream ss;
        ss << pointCount << "," << N;
        return ss.str();
    }

    std::size_t pointCount, N;
    mutable std::size_t seedX, seedY;
};

int main(void)
{
    // Init seeds
    std::srand(std::time(0));

    // Warmup !
    stats<MonteCarlo, double>(MonteCarlo(128, 1));

    // Benchmark with "low" count (from 2^7 to 2^15)
    for (std::size_t c = 128; c <= 32768; c *= 2) {
        // Do 100 measurements for low point count
        for (std::size_t N = 1; N <= c && N <= 8192; N *= 2) stats<MonteCarlo, Real>(MonteCarlo(c, N), 100);
    }

    // Benchmark with "high" count (from 2^16 to 2^22 in ~8 steps)
    for (std::size_t c = 65536; c <= 4194304; c += 524288) {
        // Do 10 measurements for each high point count
        for (std::size_t N = 1; N <= c && N <= 8192; N *= 8) stats<MonteCarlo, Real>(MonteCarlo(c, N), 10);
    }

    return 0;
}

