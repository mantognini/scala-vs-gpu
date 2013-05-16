
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
#include <thrust/random.h>
#include <thrust/generate.h>
#include <thrust/sort.h>

typedef float Real;

__host__ __device__
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
    const unsigned int CO; ///< number of new individuals (cross over) per generation

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
        // Use a counter for random number so that the random number are really random !
        thrust::counting_iterator<std::size_t> randomCount(0); // (for generator only)

        // Step 1 + 2.
        // -----------
        //
        // Generate a population & evaluate it
        EntityPopDevice epopd(settings.size);
        FitnessPopDevice fpopd(settings.size);
        thrust::transform(randomCount, randomCount + settings.size, epopd.begin(), generator);
        randomCount += settings.size;
        // Evaluate it
        thrust::transform(epopd.begin(), epopd.end(), fpopd.begin(), evaluator);
        // Now sort it
        thrust::sort_by_key(fpopd.begin(), fpopd.end(), epopd.begin());

        // Copy data back to host
        EntityPopHost epoph = epopd;
        FitnessPopHost fpoph = fpopd;

        // Random generators
        thrust::default_random_engine rng;

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
                thrust::uniform_int_distribution<unsigned int> uniform(rangeStart, rangeEnd);
                const unsigned int index = uniform(rng);

                // mutate the entity and recompute its fitness
                epoph[index] = mutator(epoph[index]);
                fpoph[index] = evaluator(epoph[index]);
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
                thrust::uniform_int_distribution<unsigned int> uniform(rangeStart, rangeEnd);
                const unsigned int first = uniform(rng);
                const unsigned int second = uniform(rng);

                epoph[i] = crossover(epoph[first], epoph[second]);
                fpoph[i] = evaluator(epoph[i]);
            }


            // Step 6.
            // -------
            //
            // Generate N new individuals randomly

            // Replace the last N entities (see comment at step 3)
            for (unsigned int i = settings.size - 1, count = 0; count < settings.N; ++count, --i) {
                epoph[i] = generator(*randomCount);
                ++randomCount;
                fpoph[i] = evaluator(epoph[i]);
            }


            // Step 7.
            // -------
            //
            // Evaluate the current population

            // The evaluation of new entities was already done in step 3 to 6
            // So we only sort the population

            // Copy data to device
            epopd = epoph;
            fpopd = fpoph;

            // Sort the data
            thrust::sort_by_key(fpopd.begin(), fpopd.end(), epopd.begin());

            // Copy data back to host
            epoph = epopd;
            fpoph = fpopd;


            // Step 8.
            // -------
            //
            // Goto Step 3 if the population is not stable yet

        } while (!terminator(epoph));

        std::cout << "#rounds = " << rounds << std::endl;

        // Step 9.
        // -------
        //
        // Identify the best individual from the current population

        return epoph.front(); // the population is already sorted;
    }

// private:
    // Private API
    // But public to work with thrust / cuda ...

    static const Real MIN_X = 9, MAX_X = 100, MIN_Y = 7, MAX_Y = 50;

    // Generator; random parameters in [MIN_X, MAX_X] x [MIN_Y, MAX_Y]
    struct Generator {
        Generator()
            : rng(std::time(0))
            , distX(MIN_X, MAX_X)
            , distY(MIN_Y, MAX_Y) {
        }

        __host__ __device__
        Params operator()(std::size_t n) { // The n is used to drop some random numbers
            rng.discard(2 * n); // since we take two random numbers
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
        Real ax = as.first,
             ay = as.second,
             bx = bs.first,
             by = bs.second;

        return Params((ax + bx) / Real(2), (ay + by) / Real(2));
    }


    // Mutator; takes a normal distribution to shift the current value
    __host__ __device__
    Params mutator(Params const& ps) {
        // TODO implement me !
        return ps;
    }


    // Terminator; stop evolution when population has (relatively) converged
    bool terminator(EntityPopHost const& pop) {
        // Compute average on x and y axes
        Real avgX(0), avgY(0);
        for (EntityPopHost::const_iterator itps = pop.begin(); itps != pop.end(); ++itps) {
            Real x = (*itps).first;
            Real y = (*itps).second;

            avgX += x;
            avgY += y;
        }
        avgX /= pop.size();
        avgY /= pop.size();

        // Stop when 75% of the population is in the range [(1 - ε) * µ, (1 + ε) * µ]
        const unsigned int maxOuts = pop.size() * 0.25;
        const Real EPSILON = 0.02;

        unsigned int outs = 0;
        for (EntityPopHost::const_iterator itps = pop.begin(); itps != pop.end(); ++itps) {
            Real x = (*itps).first;
            Real y = (*itps).second;

            if (!isClose(x, avgX, EPSILON) || !isClose(y, avgY, EPSILON)) {
                ++outs;
            }
        }

        return outs <= maxOuts;
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


