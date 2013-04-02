
#include <vector>
#include <random>
#include <sstream>

typedef double Real;
typedef std::vector<Real> Matrix;

std::ostream& operator<<(std::ostream& out, Matrix const& m);

#include "stats.hpp"

// Compute the NxN matrix multiplication of a lower triangular matrix A with a square matrix B

/*!
 * @brief Randomly generate a number on a uniform distribution
 *
 * @param min lower bound
 * @param max upper bound
 * @return a random number fitting the uniform distribution
 *
 * @note function imported from prj-sv-ba2
 */
template <typename T>
T uniform(T min, T max)
{
    static std::default_random_engine algo;
    
    static bool initialise = true;
    if (initialise) {
        initialise = false;
        std::random_device rd;
        algo.seed(rd());
    }

    typedef typename std::is_integral<T> condition;
    typedef typename std::uniform_int_distribution<T> integer_dist;
    typedef typename std::uniform_real_distribution<T> real_dist;

    typedef typename std::conditional<condition::value,
                                      integer_dist,
                                      real_dist>::type distribution_type;

    distribution_type dist(min, max);

    return dist(algo);
}

std::ostream& operator<<(std::ostream& out, Matrix const& m)
{
    const std::size_t NN = m.size();
    for (std::size_t i = 0; i < NN; ++i) {
        out << m[i] << (i < NN - 1 ? ";" : "");
    }
    return out;
}

struct TriMatrixMul
{
    // N is the dimension of the matrixes
    TriMatrixMul(std::size_t N)
    : N(N)
    { /* */ }

    // Perform the computation
    Matrix operator()() const {
        // Create a random generator (we don't care about the bounds in this benchmark)
        const auto randGenerator = []() -> Real { return uniform<Real>(-100, 100); };

        // Create A, a lower triangular matrix
        Matrix A(N * (N + 1) / 2, 0.0);
        std::generate(A.begin(), A.end(), randGenerator);

        // Create B, a square matrix
        Matrix B(N * N, 0.0);
        std::generate(B.begin(), B.end(), randGenerator);

        // Create result matrix C
        Matrix C(N * N, 0.0);

        // Compute the result
        for (std::size_t i = 0, offset = 0; i < N; offset += ++i) {
            for (std::size_t j = 0; j < N; ++j) {
                Real sum = 0;
                for (std::size_t k = 0; k <= i; ++k) {
                    sum += A[offset + k] * B[k * N + j];
                }
                C[i * N + j] = sum;
            }
        }

        return C;
    }

    std::string csvdescription() const {
        std::stringstream ss;
        ss << N;
        return ss.str();
    }

    std::size_t N;
};


int main(int argc, const char * argv[])
{
    stats<TriMatrixMul, Matrix>(TriMatrixMul(10), 10);

    return 0;
}

