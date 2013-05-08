/*
 * infosv
 * sept 2012
 * Marco Antognini
 */

#ifndef INFOSV_RANDOM_NORMAL_HPP
#define INFOSV_RANDOM_NORMAL_HPP

#include <cmath>
#include <random>

/*!
 * @brief Randomly generate a number on a normal distribution
 *
 * @param mu mean
 * @param sigma2 variance
 * @return a random number fitting the normal(mu, sigma2) distribution
 */
double normal(double mu, double sigma2);

#endif // INFOSV_RANDOM_NORMAL_HPP

