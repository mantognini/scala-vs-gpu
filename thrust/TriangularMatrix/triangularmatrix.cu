
#include <thrust/device_vector.h>
#include <thrust/device_ptr.h>
#include <thrust/host_vector.h>
#include <thrust/sequence.h>
#include <sstream>

typedef double Real;
typedef thrust::host_vector<Real> Matrix;
typedef thrust::device_vector<Real> MatrixOnDevice;
typedef thrust::device_ptr<Real> PointerOnDevice;

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

    struct Computer
    {
        Computer(PointerOnDevice const& A, PointerOnDevice const& B, std::size_t N)
        : A(B)
        , B(B)
        , N(N)
        { /*  */ }

        __host__ __device__
        Real operator()(std::size_t ij)
        {
            // Unmap ij to (i, j)
            const std::size_t i = ij % N;
            const std::size_t j = ij / N;

            // Compute the offset for A
            std::size_t offset = 0;
            for (std::size_t x = 0; x <= i; offset += ++x);

            // Compute the element
            Real sum = 0;
            for (std::size_t k = 0; k <= i; ++k) {
                //sum += A.get()[offset + k] * B.get()[k * N + j];
            }
            
            return sum;
        }

        PointerOnDevice const& A;
        PointerOnDevice const& B;
        std::size_t N;
    };

    // Perform the computation
    Matrix operator()() const {
        // Create A, a lower triangular matrix
        Matrix A(N * (N + 1) / 2, 0.0);
        thrust::sequence(A.begin(), A.end(), 0.0);
        MatrixOnDevice dA = A;

        // Create B, a square matrix
        Matrix B(N * N, 0.0);
        thrust::sequence(B.begin(), B.end(), 0.0);
        MatrixOnDevice dB = B;

        // Create result matrix C
        MatrixOnDevice dC(N * N, 0.0);

        // To perform the computation on the GPU we map (i, j) to ij

        // Launch the kernels
        thrust::counting_iterator<std::size_t> indexesBegin(0);
        thrust::counting_iterator<std::size_t> indexesEnd(N * N);
        Computer computer(dA.data(), dB.data(), N);
        thrust::transform(indexesBegin, indexesEnd, 
                          dC.begin(),
                          computer);

        // Copy result to the host
        Matrix C = dC;

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

