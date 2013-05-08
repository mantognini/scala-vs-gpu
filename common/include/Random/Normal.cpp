/*
 * infosv
 * sept 2012
 * Marco Antognini
 */

#include "Normal.hpp"

double normal(double mu, double sigma2)
{
    static std::default_random_engine algo;

    static bool initialise = true;
    if (initialise) {
        initialise = false;
        std::random_device rd;
        algo.seed(rd());
    }

    typedef std::normal_distribution<> distribution_type;

    distribution_type dist(mu, std::sqrt(sigma2));

    return dist(algo);
}
