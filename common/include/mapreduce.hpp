
#ifndef MAP_REDUCE_HPP
#define MAP_REDUCE_HPP

#include <algorithm>
#include <functional>

/*!
 * Map-Reduce a collection of T into an instance of U
 *
 * @tparam T type of the objects to map
 * @tparam U result of the map
 * @tparam InIt iterator on Ts
 *
 * @param first iterator, usual beginning of a collection
 * @param last iterator, usual end of a collection
 * @param mapper function to transform T into U
 * @param reducer function to combine Us together
 * @param z initial U
 */
template <typename T, typename U, typename InIt>
U mapreduce(InIt first,
            InIt last,
            std::function<U(T)> mapper,
            std::function<U(U, U)> reducer,
            U z)
{
    U result = z;

    std::for_each(first, last, [&](T const& t) {
    	result = reducer(result, mapper(t));
    });

    return result;
}

#endif
