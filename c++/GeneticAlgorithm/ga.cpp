
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
    : myPop(size, nullptr)
    {
    	for (unsigned int i = 0; i < size; ++i) {
    		myPop[i] = generator();
    	}
    }

    /// Dtor
    ~Population()
    {
    	deluge();
    }

private:
	// Private methods

	/// Clear the population completly
	void deluge()
	{

	}

private:
	// Data
	Pop myPop;
	EntityGenerator generator;
};


class Entity
{
public:
    Entity() {}
    ~Entity() {}

    /* data */
};

int main(int, char const**)
{
	unsigned int const SIZE = 100;
	auto generator = []() -> Entity* { return new Entity(); };
	Population<Entity> pop(SIZE, generator);


	return 0;
}


