
#include <vector>
#include <functional>

template <typename E>
class Population
{
public:
    // Type Aliases

    typedef typename std::function<E*()> EntityGenerator;
    typedef typename std::vector<E*> Pop;

public:
    // Public API

    /*
     * Ctor
     *
     * @param size size of the population
     * @param generator Generate new Entity randomly; the ownership of those objects is transfered to this Population
     */
    Population(unsigned int size, EntityGenerator generator)
    : generator(generator) {
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
    EntityGenerator generator;
};


// TODO implement this class
class BooleanExpression
{
public:
    /* data */
};

int main(int, char const**)
{
    // Initialise a population of boolean expressions
    unsigned int const SIZE = 100;
    auto generator = []() -> BooleanExpression* {
    	// TODO add randomness
        return new BooleanExpression();
    };
    Population<BooleanExpression> pop(SIZE, generator);




    return 0;
}

