
#include "Random/Uniform.hpp"
#include "Random/Normal.hpp"
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

bool isClose(Real value, Real target, Real flex)
{
    return (1 - flex) * target <= value && value <= (1 + flex) * target;
}

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

    typedef std::tuple<E, double> EntityFitness;
    typedef std::vector<EntityFitness> Pop;

    typedef typename std::function<E()> Generator;
    typedef typename std::function<Real(E const&)> Evaluator; ///< the bigger the better it is
    typedef typename std::function<E(E const&, E const&)> CrossOver;
    typedef typename std::function<E(E const&)> Mutator;

    typedef typename std::function<bool(Pop const&)> Terminator;

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
     * @param crossover Takes two entities to produce a new one
     * @param mutator Mutate an entity
     * @param terminator Determine if the population has converged or not
     */
    Population(Settings settings, Generator generator, Evaluator evaluator, CrossOver crossover, Mutator mutator, Terminator terminator)
        : settings(settings)
        , generator(generator)
        , evaluator(evaluator)
        , crossover(crossover)
        , mutator(mutator)
        , terminator(terminator) {
    }

    /// Apply the genetic algorithm until the population stabilise and return the best entity
    E run() {

        const auto entityWithFitness = [&](E const& entity) -> EntityFitness {
            return EntityFitness(entity, evaluator(entity));
        };

        // Step 1 + 2.
        // -----------
        //
        // Generate a population & evaluate it
        Pop pop; // collection of (entitiy, fitness)
        std::generate_n(std::back_inserter(pop), settings.size, [&]() {
            return entityWithFitness(generator());
        });
        // Now sort it
        const auto comparator = [](EntityFitness const& a, EntityFitness const& b) -> bool {
            return std::get<1>(a) > std::get<1>(b); // sort by fitness. bigger is better
        };
        std::sort(pop.begin(), pop.end(), comparator);

        unsigned int rounds = 0;

        do {
            ++rounds;

            // Step 3.
            // -------
            //
            // Remove the worse K individuals

            // Skipped -> replace those entities with step 5 & 6


            // Step 4.
            // -------
            //
            // Mutate M individuals of the population

            // Choose M random individuals from the living ones, that is in range [0, size-K[
            for (unsigned int count = 0; count < settings.M; ++count) {
                const unsigned int rangeStart = 0;
                const unsigned int rangeEnd = settings.size - settings.K - 1;
                const unsigned int index = uniform<unsigned int>(rangeStart, rangeEnd);

                pop[index] = entityWithFitness(mutator(std::get<0>(pop[index])));
            }


            // Step 5.
            // -------
            //
            // Create CO new individuals with CrossOver

            // Replace the last CO entities before the N last ones (see comment at step 3)
            for (unsigned int i = settings.size - settings.N - 1, count = 0; count < settings.CO; ++count) {
                // Select two random entities from the living ones, that is in range [0, size-K[
                const unsigned int rangeStart = 0;
                const unsigned int rangeEnd = settings.size - settings.K - 1;
                const unsigned int first = uniform<unsigned int>(rangeStart, rangeEnd);
                const unsigned int second = uniform<unsigned int>(rangeStart, rangeEnd);

                pop[i] = entityWithFitness(crossover(std::get<0>(pop[first]), std::get<0>(pop[second])));
            }


            // Step 6.
            // -------
            //
            // Generate N new individuals randomly

            // Replace the last N entities (see comment at step 3)
            for (unsigned int i = settings.size - 1, count = 0; count < settings.N; ++count, --i) {
                pop[i] = entityWithFitness(generator());
            }


            // Step 7.
            // -------
            //
            // Evaluate the current population

            // The evaluation of new entities was already done in step 3 to 6
            // So we only sort the population
            std::sort(pop.begin(), pop.end(), comparator);


            // Step 8.
            // -------
            //
            // Goto Step 3 if the population is not stable yet

        } while (!terminator(pop));

        std::clog << "#Round : " << rounds << std::endl;


        // Step 9.
        // -------
        //
        // Identify the best individual from the current population

        return std::get<0>(pop.front()); // the population is already sorted
    }

private:
    // Data
    Settings settings;
    Generator generator;
    Evaluator evaluator;
    CrossOver crossover;
    Mutator mutator;
    Terminator terminator;
};


typedef std::tuple<Real, Real> Params;


int main(int, char const**)
{
    using Population = Population<Params>;

    // Equation :
    //
    // Sin[x - 15] / x * (y - 7) (y - 30) (y - 50) (x - 15) (x - 45)
    //
    // Range : (x, y) in [9, 100] x [7, 50]

    constexpr Real MIN_X = 9, MAX_X = 100, MIN_Y = 7, MAX_Y = 50;

    // Generator; random parameters in [MIN_X, MAX_X] x [MIN_Y, MAX_Y]
    const auto generator = []() -> Params {
        return Params(uniform(MIN_X, MAX_X), uniform(MIN_Y, MAX_Y));
    };

    // Evaluator; the biggest the better
    const auto evaluator = [](Params const& ps) -> Real {
        Real x, y;
        std::tie(x, y) = ps;

        return std::sin(x - 15) / x * (y - 7) * (y - 30) * (y - 50) * (x - 15) * (x - 45);
    };

    // CrossOver; takes the average of the two entities
    const auto crossover = [](Params const& as, Params const& bs) -> Params {
        Real ax, ay, bx, by;
        std::tie(ax, ay) = as;
        std::tie(bx, by) = bs;

        return Params((ax + bx) / Real(2), (ay + by) / Real(2));
    };

    // Mutator; takes a normal distribution to shift the current value
    const auto mutator = [](Params const& ps) -> Params {
        return ps; // TODO implement me !
    };

    // Terminator; stop evolution when population has (relatively) converged
    unsigned int count = 0; // number of rounds
    constexpr unsigned int MAX_ROUNDS = 100000;
    const auto terminator = [&](Population::Pop const& pop) -> bool {
        if (++count >= MAX_ROUNDS) {
            return true;
        }

        // Compute average on x and y axes
        Real avgX(0), avgY(0);
        for (auto const& ef: pop) {
            const Params ps = std::get<0>(ef);

            Real x, y;
            std::tie(x, y) = ps;

            avgX += x;
            avgY += y;
        }
        avgX /= pop.size();
        avgY /= pop.size();

        // Stop when 75% of the population is in the range [(1 - ε) * µ, (1 + ε) * µ]
        unsigned int maxOuts = pop.size() * 0.25;
        constexpr Real EPSILON = 0.02;

        unsigned int outs = 0;
        for (auto const& ef: pop) {
            const Params ps = std::get<0>(ef);

            Real x, y;
            std::tie(x, y) = ps;

            if (!isClose(x, avgX, EPSILON) || !isClose(y, avgY, EPSILON)) {
                ++outs;
            }
        }

        return outs <= maxOuts;
    };

    // Settings
    const Settings settings(1000, 100, 50, 50, 50);

    // Create the population
    Population pop(settings, generator, evaluator, crossover, mutator, terminator);


    // Run the Genetic Algorithm
    Real x, y;
    std::tie(x, y) = pop.run();

    std::cout << "Best is (" << x << ", " << y << ")" << std::endl;

    return 0;
}


