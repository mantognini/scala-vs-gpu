
#ifndef __STATS__HPP__
#define __STATS__HPP__

#include <SFML/System.hpp>
#include <iostream>

/*
 * Action must have two functions :
 *  - operator() which runs the action and returns a Result; 
 *  - csvdescription() which returns a string describing the parameters
 *    of the action separated by a comma.
 * 
 * Also, << for std::ostream and Result must exist.
 *
 * The format of the output is as follow :
 * 'action.csvdescription()','action()',time
 *
 * where time is expressed in µs.
 */
template <typename Action, typename Result>
void stats(Action const& action, std::size_t measureCount = 1, std::ostream& out = std::cout)
{
    for (int i = 0; i < measureCount; ++i) {
        sf::Clock clk;
        const Result r = action();
        const sf::Time time = clk.restart();
        out << action.csvdescription() << "," << r << "," << time.asMicroseconds() << std::endl;
    }
}

#endif // __STATS__HPP__

