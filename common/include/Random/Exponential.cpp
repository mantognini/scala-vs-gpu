/*
 * infosv
 * sept 2012
 * Marco Antognini
 */

#include "Exponential.hpp"

double exponential(double lambda)
{
    static std::default_random_engine algo;

    static bool initialise = true;
    if (initialise) {
        initialise = false;
        std::random_device rd;
        algo.seed(rd());
    }

    typedef std::exponential_distribution<> distribution_type;

    distribution_type dist(lambda);

    return dist(algo);
}
