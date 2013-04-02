
#include <vector>
#include <sstream>
#include <numeric>

typedef double Real;
typedef std::vector<Real> Matrix;

std::ostream& operator<<(std::ostream& out, Matrix const& m);

#include "stats.hpp"

//
// Compute the NxN matrix multiplication of a lower triangular matrix A with a square matrix B
//

// Disable output of matrix data
// #define OUTPUT_MATRIX_DATA

std::ostream& operator<<(std::ostream& out, Matrix const& m)
{
#ifdef OUTPUT_MATRIX_DATA
    const std::size_t NN = m.size();
    for (std::size_t i = 0; i < NN; ++i) {
        out << m[i] << (i < NN - 1 ? ";" : "");
    }
    return out;
#else
    return out << "skipped";
#endif
}

struct TriMatrixMul
{
    // N is the dimension of the matrixes
    TriMatrixMul(std::size_t N)
    : N(N)
    { /* */ }

    // Perform the computation
    Matrix operator()() const {
        // Create A, a lower triangular matrix
        Matrix A(N * (N + 1) / 2, 0.0);
        std::iota(A.begin(), A.end(), 0.0);

        // Create B, a square matrix
        Matrix B(N * N, 0.0);
        std::iota(B.begin(), B.end(), 0.0);

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
    // Make stats from N = 2 to N = 2^12
    for (std::size_t N = 2; N <= 4096; N *= 2) {
        stats<TriMatrixMul, Matrix>(TriMatrixMul(N), 4);
    }

    return 0;
}

