
#include "Random/Uniform.hpp"

#include <vector>
#include <functional>

template <typename E>
class Population
{
public:
    // Type Aliases

    typedef typename std::function<E*()> Generator;
    typedef typename std::function<double(E const&)> Evaluator;
    typedef typename std::vector<E*> Pop;

public:
    // Public API

    /*
     * Ctor
     *
     * @param size size of the population
     * @param generator Generate new Entity randomly; the ownership of those objects is transfered to this Population
     */
    Population(unsigned int size, Generator generator, Evaluator evaluator)
        : generator(generator)
        , evaluator(evaluator) {
        initPop(size);
    }

    /// Dtor
    ~Population() {
        deluge();
    }

    // TODO add more methods and stuff..

private:
    // Private methods

    /// Initialise the population
    void initPop(unsigned int size) {
        deluge();

        for (unsigned int i = 0; i < size; ++i) {
            pop.push_back( generator() );
        }
    }

    /// Clear the population completly
    void deluge() {
        for (auto& e: pop) {
            delete e;
            e = nullptr;
        }
        pop.clear();
    }

private:
    // Data
    Pop pop;
    Generator generator;
    Evaluator evaluator;
};


// TODO implement this class
class Polynomial
{
public:
    Polynomial();
};

class Params
{
public:
    Params(double x, double y)
        : x(x), y(y) {
        // That's it
    }

private:
    double x, y;
};

int main(int, char const**)
{
    // Evaluation range
    double const RANGE_MIN = -100000;
    double const RANGE_MAX =  100000;

    auto randomParameter = [&]() -> double {
        return uniform(RANGE_MIN, RANGE_MAX);
    };

    // Generator; random parameters
    auto generator = [&]() -> Params* {
        return new Params(randomParameter(), randomParameter());
    };

    // Evaluator; the closer to 0 the better
    auto evaluator = [&](Params const& p) -> double {
        return 0; // TODO
    };

    // Create the population
    unsigned int const SIZE = 100;
    Population<Params> pop(SIZE, generator, evaluator);


    return 0;
}


