
#include "Random/Uniform.hpp"
#include "mapreduce.hpp"

#include <vector>
#include <functional>
#include <algorithm>
#include <numeric>
#include <tuple>
#include <cmath>
#include <iostream>
#include <stdexcept>
#include <iterator>


typedef double Real;

struct Settings {
    Settings(unsigned int size, unsigned int K, unsigned int M, unsigned int N, unsigned int CO)
        : size(size)
        , K(K)
        , M(M)
        , N(N)
        , CO(CO) {
        if (!isValid()) {
            throw new std::domain_error("Invalid settings");
        }
    }

    const unsigned int size; ///< population size
    const unsigned int K; ///< number of killed per generation
    const unsigned int M; ///< number of mutated per generation
    const unsigned int N; ///< number of new individuals (random) per generation
    const unsigned int CO; ///< number of new indifiduals (cross over) per generation

    /// Make sure the settings are valid
    bool isValid() const {
        // K, M < size
        if (K >= size || M >= size) {
            return false;
        }

        // N + CO = K
        if (N + CO != K) {
            return false;
        }

        return true;
    }
};

template <typename E>
class Population
{
public:
    // Type Aliases

    typedef typename std::function<E()> Generator;
    typedef typename std::function<Real(E const&)> Evaluator; ///< the bigger the better it is

public:
    // Public API

    /*!
     * Ctor
     *
     * @param settings settings for the algorithm
     * @param generator Generate new Entity randomly;
     *        the ownership of those objects is transfered to this Population
     * @param evaluator Fitness function;
     *        the bigger the better it is
     */
    Population(Settings settings, Generator generator, Evaluator evaluator)
        : settings(settings)
        , generator(generator)
        , evaluator(evaluator) {
    }

    /// Apply the genetic algorithm until the population stabilise and return the best entity
    E run() {

        typedef std::tuple<E, double> EntityFitness;
        typedef std::vector<EntityFitness> Pop;

        // Step 1 + 2.
        // -----------
        //
        // Generate a population & evaluate it
        Pop pop; // collection of (entitiy, fitness)
        std::generate_n(std::back_inserter(pop), settings.size, [&]() {
            E entity = generator();
            return std::make_tuple(entity, evaluator(entity));
        });
        // Now sort it
        auto comparator = [](EntityFitness const& a, EntityFitness const& b) -> bool {
            return std::get<1>(a) > std::get<1>(b); // sort by fitness. bigger is better
        };
        std::sort(pop.begin(), pop.end(), comparator);


        bool running = true;
        do {

            // Step 3.
            // -------
            //
            // Remove the worse K individuals



            // Step 4.
            // -------
            //
            // Mutate M individuals of the population



            // Step 5.
            // -------
            //
            // Create CO new individuals with CrossOver



            // Step 6.
            // -------
            //
            // Generate N new individuals randomly



            // Step 7.
            // -------
            //
            // Evaluate the current population



            // Step 8.
            // -------
            //
            // Goto Step 3 if the population is not stable yet


        } while(running);


        // Step 9.
        // -------
        //
        // Identify the best individual from the current population

        return E();
    }

private:
    // Data
    Settings settings;
    Generator generator;
    Evaluator evaluator;
};


typedef std::tuple<Real, Real> Params;


int main(int, char const**)
{
    // Equation :
    //
    // Sin[x - 15] / x * (y - 7) * (y - 30)
    //
    // Range : (x, y) in [9, 30] x [7, 30]

    Real constexpr MIN_X = 9, MAX_X = 30, MIN_Y = 7, MAX_Y = 30;

    // Generator; random parameters in [MIN_X, MAX_X] x [MIN_Y, MAX_Y]
    auto generator = []() -> Params {
        return Params(uniform(MIN_X, MAX_X), uniform(MIN_Y, MAX_Y));
    };

    // Evaluator; the biggest the better
    auto evaluator = [](Params const& ps) -> Real {
        Real x, y;
        std::tie(x, y) = ps;

        return std::sin(x - 15) / x * (y - 7) * (y - 30);
    };

    // Settings
    Settings settings(100, 15, 20, 5, 15);

    // Create the population
    Population<Params> pop(settings, generator, evaluator);


    // Run the Genetic Algorithm
    Real x, y;
    std::tie(x, y) = pop.run();

    std::cout << "Best is (" << x << ", " << y << ")" << std::endl;

    return 0;
}


