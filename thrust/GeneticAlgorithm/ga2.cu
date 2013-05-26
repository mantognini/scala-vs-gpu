
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
#include <thrust/random.h>
#include <thrust/generate.h>
#include <thrust/sort.h>
#include <thrust/extrema.h>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/tuple.h>
#include <thrust/count.h>

#warning THIS IMPLEMENTATION IS IMPRECISE

typedef float Real;

__host__ __device__
bool isClose(Real value, Real target, Real flex)
{
    return (1 - flex) * target <= value && value <= (1 + flex) * target;
}

__host__ __device__
Real clamp(Real value, Real min, Real max)
{
    const Real diff = max - min;
    while (value < min) {
        value += diff;
    }

    while (value > max) {
        value -= diff;
    }

    return value;
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

        // And init the random generator of generator and mutator
        generator.setSeed(rand());
        mutator.setSeed(rand());

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
            // Evaluate tehm
            thrust::transform(
                epopd.end() - settings.K - 1, epopd.end(), // input
                fpopd.begin()  - settings.K - 1,           // ouput
                evaluator                                  // mapper
            );
            thrust::sort_by_key(fpopd.begin(), fpopd.end(), epopd.begin());

            // Step 5.
            // -------
            //
            // Mutate some individuals of the population

            // Use prob of mutation instead of fixed settings (if close to max, then probably not mutated)
            mutator.maxfitness = fpopd.front();
            mutator.best = epopd.front();
            thrust::transform_if(
                thrust::make_zip_iterator(                  // data input start
                    thrust::make_tuple(
                        epopd.begin(),                              // actual data
                        thrust::counting_iterator<std::size_t>(0)   // random 'index'
                    )
                ),
                thrust::make_zip_iterator(                  // data input end
                    thrust::make_tuple(
                        epopd.end(),
                        thrust::counting_iterator<std::size_t>(epopd.size())
                    )
                ),
                fpopd.begin(),                  // controller input
                epopd.begin(),                  // data output (in-place)
                mutator,                        // mapper             [ operator(Params) ]
                mutator                         // controller         [ operator(Real)   ]
            );

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

        } while (!terminator(epopd) && rounds < 10000);

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
            : rng(std::rand())
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
    struct Mutator {
        Mutator()
            : rng(std::rand()) {
        }

        // Mutate action
        __host__ __device__
        Params operator()(thrust::tuple<Params, std::size_t> const& tuple) {
            Params ps = thrust::get<0>(tuple);
            const std::size_t n = thrust::get<1>(tuple);
            rng.discard(2 * n);
            thrust::normal_distribution<Real> distX(best.first, (MAX_X - MIN_X) / 8);
            thrust::normal_distribution<Real> distY(best.second, (MAX_Y - MIN_Y) / 8);
            ps.first = clamp(ps.first + distX(rng), MIN_X, MAX_X);
            ps.second = clamp(ps.second + distY(rng), MIN_Y, MAX_Y);
            return ps;
        }

        // Mutate decider
        __host__ __device__
        bool operator()(Real fitness) {
            return fitness / maxfitness < 0.5;
        }

        void setSeed(unsigned int seed) {
            rng.seed(seed);
        }

        Real maxfitness; // must be updated before calling mutate decider !
        Params best;

    private:
        // Random generators
        thrust::default_random_engine rng;
    } mutator;

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

        // Stop when P % of the population is in the range [(1 - ε) * µ, (1 + ε) * µ]
        const Real P = 75;
        const std::size_t maxOuts = pop.size() * (Real(1) - P / Real(100));
        const Real EPSILON = 0.05;

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


