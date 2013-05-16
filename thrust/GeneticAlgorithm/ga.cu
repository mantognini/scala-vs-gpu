
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

template <typename T, typename U>
struct SumPair {
    typedef typename thrust::pair<T, U> Pair;

    SumPair() {
    }

    __host__ __device__
    Pair operator()(Pair const& as, Pair const& bs) const {
        return Pair(as.first + bs.first, as.second + bs.second);
    }
};

struct Settings {
    Settings(unsigned int size, unsigned int K)
        : size(size)
        , K(K) {
        if (!isValid()) {
            throw new std::domain_error("Invalid settings");
        }
    }

    const unsigned int size; ///< population size
    const unsigned int K; ///< number of killed per generation

    /// Make sure the settings are valid
    bool isValid() const {
        return K < size;
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
        std::srand(std::time(0));
    }

    /// Apply the genetic algorithm until the population stabilise and return the best entity
    Params run() {
        // Use a counter for random number so that the random number are really random !
        thrust::counting_iterator<std::size_t> randomCount(0); // (for generator only)

        // And init the random generator of generator
        generator.setSeed(rand());

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

        unsigned int rounds = 0;

        do {
            ++rounds;

            // Step 3 + 4
            // ----------
            //
            // Remove the worse K individuals & generate K new individuals randomly

            // Replace the last N entities
            thrust::transform(randomCount, randomCount + settings.K, epopd.end() - settings.K - 1, generator);
            randomCount += settings.K;
            // Evaluate it
            thrust::transform(epopd.end() - settings.K - 1, epopd.end(),
                              fpopd.begin()  - settings.K - 1,
                              evaluator);

            // Step 5.
            // -------
            //
            // Mutate some individuals of the population

            // TODO use prob of mutation instead of fixed settings.
            // use increasing prob of mutation when the entity is far from max


            // Step 6.
            // -------
            //
            // Evaluate the current population

            // The evaluation of new entities was already done in step 3 to 6
            // So we only sort the population

            // Sort the data
            thrust::sort_by_key(fpopd.begin(), fpopd.end(), epopd.begin());


            // Step 7.
            // -------
            //
            // Goto Step 3 if the population is not stable yet

        } while (!terminator(epopd));

        std::cout << "#rounds = " << rounds << std::endl;

        // Step 8.
        // -------
        //
        // Identify the best individual from the current population

        return epopd.front(); // the population is already sorted;
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

        void setSeed(unsigned int seed) {
            rng.seed(seed);
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


    // Mutator; takes a normal distribution to shift the current value
    __host__ __device__
    Params mutator(Params const& ps) {
        // TODO implement me !
        return ps;
    }

    struct IsOut {
        IsOut(Real avgX, Real avgY, Real epsilon)
            : avgX(avgX)
            , avgY(avgY)
            , epsilon(epsilon) {
        }

        __host__ __device__
        bool operator()(Params const& ps) const {
            return !isClose(ps.first, avgX, epsilon) || !isClose(ps.second, avgY, epsilon);
        }

        const Real avgX, avgY, epsilon;
    };

    // Terminator; stop evolution when population has (relatively) converged
    bool terminator(EntityPopDevice const& pop) {
        // Compute average on x and y axes
        const SumPair<Real, Real> reducer;
        Params sum = thrust::reduce(pop.begin(), pop.end(), Params(0, 0), reducer);
        Real avgX = sum.first / pop.size();
        Real avgY = sum.second / pop.size();

        // Stop when 75% of the population is in the range [(1 - ε) * µ, (1 + ε) * µ]
        const std::size_t maxOuts = pop.size() * 0.25;
        const Real EPSILON = 0.02;

        const IsOut predicate(avgX, avgY, EPSILON);
        const std::size_t outs = thrust::count_if(pop.begin(), pop.end(), predicate);

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
    const Settings settings(1000, 100);

    // Create the population
    Population pop(settings);

    // Run the Genetic Algorithm
    stats<Action, Population::Params>(Action(pop), 100);

    return 0;
}


