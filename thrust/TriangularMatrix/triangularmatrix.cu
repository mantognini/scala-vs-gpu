
#include <thrust/device_vector.h>
#include <thrust/device_ptr.h>
#include <thrust/host_vector.h>
#include <thrust/sequence.h>
#include <sstream>
#include <vector>

typedef float Real;
typedef thrust::host_vector<Real> Matrix;
typedef thrust::device_vector<Real> MatrixOnDevice;
typedef Real* PointerOnDevice;

std::ostream& operator<<(std::ostream& out, Matrix const& m);

#include "stats.hpp"

//
// Compute the NxN matrix multiplication of a lower triangular matrix A with a square matrix B
//

// Disable output of matrix data
#define OUTPUT_MATRIX_DATA

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
                sum += A[offset + k] * B[k * N + j];
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

        // Memory allocation
        PointerOnDevice dARawPtr = 0;
        const std::size_t dASize = N * (N + 1) / 2;
        cudaMalloc((void**)&dARawPtr, dASize * sizeof(Real));

        // Init its values with 0, 1, 2, ... M
        thrust::device_ptr<Real> dAPtr = thrust::device_pointer_cast(dARawPtr);
        thrust::sequence(dAPtr, dAPtr + dASize, 0.0f);

        // Create B, a square matrix

        // Memory allocation
        PointerOnDevice dBRawPtr = 0;
        const std::size_t dBSize = N * N;
        cudaMalloc((void**)&dBRawPtr, dBSize * sizeof(Real));

        // Init its values with 0, 1, 2, ... N * N
        thrust::device_ptr<Real> dBPtr = thrust::device_pointer_cast(dBRawPtr);
        thrust::sequence(dBPtr, dBPtr + dBSize, 0.0f);

        // Create result matrix C

        // Create C, a square matrix for the result of A * B

        // Memory allocation
        PointerOnDevice dCRawPtr = 0;
        const std::size_t dCSize = N * N;
        cudaMalloc((void**)&dCRawPtr, dCSize * sizeof(Real));

        thrust::device_ptr<Real> dCPtr = thrust::device_pointer_cast(dCRawPtr);

        // To perform the computation on the GPU we map (i, j) to ij

        // Launch the kernels
        thrust::counting_iterator<std::size_t> indexesBegin(0);
        thrust::counting_iterator<std::size_t> indexesEnd(N * N);
        Computer computer(dARawPtr, dBRawPtr, N);
        thrust::transform(indexesBegin, indexesEnd, dCPtr, computer);

        // Copy result to the host
        Matrix C(dCSize);
        cudaMemcpy(C.data(), dCRawPtr, dCSize * sizeof(Real), cudaMemcpyDeviceToHost);

        cudaFree(dCRawPtr);
        dCRawPtr = 0;

        cudaFree(dBRawPtr);
        dBRawPtr = 0;

        cudaFree(dARawPtr);
        dARawPtr = 0;

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

