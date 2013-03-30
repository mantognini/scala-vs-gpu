    
#include <iostream>
#include <SFML/System.hpp>
#include <random>
#include <functional>

namespace mc {
    
    typedef double Real;
    typedef std::uniform_real_distribution<Real> RealDistribution;
    typedef std::default_random_engine RandomEngine;

    Real computeRatio(std::size_t pointCount) {
        // Define two random number generators gX and gY
        RandomEngine algoX, algoY;
        std::random_device rd;
        algoX.seed(rd());
        algoY.seed(rd());
        RealDistribution dist(0, 1);
        auto gX = std::bind(dist, algoX);
        auto gY = std::bind(dist, algoY);

        // TODO...
    }


}

std::ostream& operator<<(std::ostream& out, sf::Time const& t)
{
    sf::Int64 micros = t.asMicroseconds();
    return out << micros << "µs";
}

int main(int argc, const char * argv[])
{
    sf::Clock clk;
    
    const sf::Time time = clk.restart();
    std::cout << "ratio computed in " << time << std::endl;

    return 0;
}

