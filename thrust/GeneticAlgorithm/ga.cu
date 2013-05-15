
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
#include <thrust/random.h>
#include <thrust/generate.h>
#include <thrust/sort.h>
#include "stats.hpp"

typedef float Real;

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


class Population
{
public:
    // Type Aliases

    // Define Entity & Fitness Pop using SoA (Structure of Arrays)
    typedef thrust::pair<Real, Real> Params;
    typedef thrust::device_vector<Params> EntityPopDevice;
    typedef thrust::device_vector<Real> FitnessPopDevice;
    typedef thrust::host_vector<Params> EntityPopHost;
    typedef thrust::host_vector<Real> FitnessPopHost;


    // Equation :
    //
    // Sin[x - 15] / x * (y - 7) (y - 30) (y - 50) (x - 15) (x - 45)
    //
    // Range : (x, y) in [9, 100] x [7, 50]

public:
    // Public API

    /*!
     * Ctor
     *
     * @param settings settings for the algorithm
     */
    Population(Settings settings)
        : settings(settings) {
    }

    /// Apply the genetic algorithm until the population stabilise and return the best entity
    Params run() {

        // Step 1 + 2.
        // -----------
        //
        // Generate a population & evaluate it
        EntityPopDevice epopd(settings.size);
        FitnessPopDevice fpopd(settings.size);
        thrust::generate(epopd.begin(), epopd.end(), generator);
        // Evaluate it
        thrust::transform(epopd.begin(), epopd.end(), fpopd.begin(), evaluator);
        // Now sort it
        thrust::sort_by_key(fpopd.begin(), fpopd.end(), epopd.begin());

        // Copy data back to host
        EntityPopHost epoph = epopd;
        FitnessPopHost fpoph = fpopd;

        do {
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

            // TODO implement me !


            // Step 5.
            // -------
            //
            // Create CO new individuals with CrossOver

            // Replace the last CO entities before the N last ones (see comment at step 3)

            // TODO implement me !


            // Step 6.
            // -------
            //
            // Generate N new individuals randomly

            // Replace the last N entities (see comment at step 3)

            // TODO implement me !


            // Step 7.
            // -------
            //
            // Evaluate the current population

            // The evaluation of new entities was already done in step 3 to 6
            // So we only sort the population

            // TODO implement me !


            // Step 8.
            // -------
            //
            // Goto Step 3 if the population is not stable yet

        } while (!terminator(epoph));

        // Step 9.
        // -------
        //
        // Identify the best individual from the current population

        // TODO implement me !
        return Params();
    }

// private:
    // Private API
    // But public to work with thrust / cuda ...

    static const Real MIN_X = 9, MAX_X = 100, MIN_Y = 7, MAX_Y = 50;

    // Generator; random parameters in [MIN_X, MAX_X] x [MIN_Y, MAX_Y]
    struct Generator {
        Generator()
            :rng(std::rand())
            , distX(MIN_X, MAX_X)
            , distY(MIN_Y, MAX_Y) {
        }

        __host__ __device__
        Params operator()() {
            return Params(distX(rng), distY(rng));
        }

    private:
        // Random generators
        thrust::default_random_engine rng;
        thrust::uniform_real_distribution<Real> distX, distY;
    } generator;

    // Evaluator; the biggest the better
    struct Evaluator {
        __host__ __device__
        Real operator()(Params const& ps) {
            Real x = ps.first, y = ps.second;

            return std::sin(x - 15) / x * (y - 7) * (y - 30) * (y - 50) * (x - 15) * (x - 45);
        }
    } evaluator;

    // CrossOver; takes the average of the two entities
    __host__ __device__
    Params crossover(Params const& as, Params const& bs) {
        // TODO implement me !
        return Params();
    }


    // Mutator; takes a normal distribution to shift the current value
    __host__ __device__
    Params mutator(Params const& ps) {
        // TODO implement me !
        return ps;
    }


    // Terminator; stop evolution when population has (relatively) converged
    bool terminator(EntityPopHost const& pop) {
        // TODO implement me !
        return true;
    }

private:
    // Data
    Settings settings;
};


struct Action {
    Action(Population& popref)
        : popref(popref) {
    }

    Population::Params operator()() const {
        return popref.run();
    }

    std::string csvdescription() const {
        return "ø"; // no explicit parameters for the computation
    }

    Population& popref;
};

std::ostream& operator<<(std::ostream& out, Population::Params const& ps)
{
    return out << ps.first << "," << ps.second;
}

#include "stats.hpp"

int main(int, char const**)
{
    // Settings
    const Settings settings(1000, 100, 50, 50, 50);

    // Create the population
    Population pop(settings);

    // Run the Genetic Algorithm
    stats<Action, Population::Params>(Action(pop), 100);

    return 0;
}


