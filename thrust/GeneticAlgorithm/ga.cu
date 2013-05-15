
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
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

template <typename E>
class Population
{
public:
    // Type Aliases

    // Define Entity & Fitness Pop using SoA (Structure of Arrays)
    typedef thrust::device_vector<E> EntityPop;
    typedef thrust::device_vector<Real> FitnessPop;

    typedef E (*Generator)();
    typedef Real (*Evaluator)(E const&); ///< the bigger the better it is
    typedef E (*CrossOver)(E const&, E const&);
    typedef E (*Mutator)(E const&);
    typedef bool (*Terminator)(EntityPop const&);

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

        // Step 1 + 2.
        // -----------
        //
        // Generate a population & evaluate it
        EntityPop epop;
        FitnessPop fpop;
        // TODO generate entities
        // Now sort it
        // TODO sort the population

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

        } while (!terminator(pop));

        // Step 9.
        // -------
        //
        // Identify the best individual from the current population

        // TODO implement me !
        return E();
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


// Define Params
typedef thrust::pair<Real, Real> Params;


template <typename E>
struct Action {
    Action(Population<E>& popref)
        : popref(popref) {
    }

    E operator()() const {
        return popref.run();
    }

    std::string csvdescription() const {
        return "ø"; // no explicit parameters for the computation
    }

    Population<E>& popref;
};

std::ostream& operator<<(std::ostream& out, Params const& ps)
{
    return out << ps.first << "," << ps.second;
}

#include "stats.hpp"

int main(int, char const**)
{
    typedef Population<Params> Population;

    // Equation :
    //
    // Sin[x - 15] / x * (y - 7) (y - 30) (y - 50) (x - 15) (x - 45)
    //
    // Range : (x, y) in [9, 100] x [7, 50]

    const Real MIN_X = 9, MAX_X = 100, MIN_Y = 7, MAX_Y = 50;

    // Generator; random parameters in [MIN_X, MAX_X] x [MIN_Y, MAX_Y]
    
    // TODO create a function
    

    // Evaluator; the biggest the better

    // TODO create a function

    // CrossOver; takes the average of the two entities
    
    // TODO create a function

    // Mutator; takes a normal distribution to shift the current value
    
    // TODO create a function

    // Terminator; stop evolution when population has (relatively) converged
    
    // TODO create a function

    // Settings
    const Settings settings(1000, 100, 50, 50, 50);

    // Create the population
    Population pop(settings, generator, evaluator, crossover, mutator, terminator);


    // Run the Genetic Algorithm
    stats<Action<Params>, Params>(Action<Params>(pop), 100);

    return 0;
}


