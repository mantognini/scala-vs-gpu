
#include "Random/Uniform.hpp"
#include "mapreduce.hpp"

#include <vector>
#include <functional>
#include <algorithm>
#include <numeric>
#include <tuple>
#include <cmath>
#include <iostream>


typedef double Real;



template <typename E>
class Population
{
public:
    // Type Aliases

    typedef typename std::function<E()> Generator;
    typedef typename std::function<Real(E const&)> Evaluator; ///< the bigger the better it is
    typedef typename std::vector<E> Pop;

public:
    // Public API

    /*!
     * Ctor
     *
     * @param size size of the population
     * @param generator Generate new Entity randomly;
     *        the ownership of those objects is transfered to this Population
     * @param evaluator Fittness function;
     *        the bigger the better it is
     */
    Population(unsigned int size, Generator generator, Evaluator evaluator)
        : size(size)
        , generator(generator)
        , evaluator(evaluator) {
    }

    /// Dtor
    ~Population() {
        deluge();
    }

    /// Apply the genetic algorithm until the population stabilise and return the best entity
    E run() {
        // TODO
        return E();
    }




    }

private:
    // Data
    unsigned int size;
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

    // Create the population
    unsigned int const SIZE = 100;
    Population<Params> pop(SIZE, generator, evaluator);


    // Run the Genetic Algorithm
    Real x, y;
    std::tie(x, y) = pop.run();

    std::cout << "Best is (" << x << ", " << y << ")" << std::endl;

    return 0;
}


