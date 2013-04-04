#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
#include "cuda_complex.hpp"
#include "stats.hpp"

#ifdef SAVE_IMAGE
    #include <SFML/Graphics.hpp>
#endif

typedef float Real;

typedef complex<Real> Complex;

std::ostream& operator<<(std::ostream& out, Complex const& z)
{
    return out << "(" << z.real() << ";" << z.imag() << ")";
}

typedef std::pair<Complex, Complex> ComplexRange;

std::ostream& operator<<(std::ostream& out, ComplexRange const& range)
{
    return out << "{" << range.first << ";" << range.second << "}";
}

typedef bool Color;

static const Color inSetColor = true;
static const Color notInSetColor = false;

typedef std::size_t Index;

struct Mandelbrot : public thrust::unary_function<Index, Color>
{
    Mandelbrot(std::size_t side, std::size_t maxIterations,
               ComplexRange const& range)
    : side(side)
    , maxIterations(maxIterations)
    , range(range)
    { /* - */ }

    // Perform the set computation
    void operator()() const
    {
        // Create an array on the device
        const std::size_t size = side * side;
        thrust::device_vector<Color> deviceImg(size);

        // Then, transform the indexes into 'colors'
        thrust::transform(thrust::counting_iterator<Index>(0),
                          thrust::counting_iterator<Index>(size),
                          deviceImg.begin(),
                          *this); // apply op()(Index)

        // Copy the data to the host memory
        thrust::host_vector<Color> img = deviceImg;

        #ifdef SAVE_IMAGE
        static std::size_t imgId = 0;

        // Export it to png
        sf::Image png; png.create(side, side, sf::Color::White);
        for (std::size_t x = 0; x < side; ++x) {
            for (std::size_t y = 0; y < side; ++y) {
                png.setPixel(x, y, img[y * side + x] == inSetColor ? sf::Color::Black : sf::Color::White);
            }
        }

        std::stringstream filename;
        filename << "tmp/fractal_"
                 << imgId
                 << "_"
                 << csvdescription()
                 << ".png";
        png.saveToFile(filename.str());
        ++imgId;
        #endif
    }

    __host__ __device__
    Color operator()(Index const& index)
    {
        const unsigned int x = index % side;
        const unsigned int y = index / side; // integer division

        const Complex c(
            range.first.real() + x / (side - Real(1.0f)) * (range.second.real() - range.first.real()),
            range.first.imag() + y / (side - Real(1.0f)) * (range.second.imag() - range.first.imag())
        );

        Complex z( 0, 0 );

        std::size_t iter = 0;
        for (iter = 0; iter < maxIterations && abs(z) < Real(2.0f); ++iter) {
            z = z * z + c;
        }

        return iter == maxIterations ? inSetColor : notInSetColor;
    }

    std::string csvdescription() const 
    {
        std::stringstream ss;
        ss << side << "," 
           << maxIterations << "," 
           << range;
        return ss.str();
    }

    std::size_t side, maxIterations;
    ComplexRange range;
};

int main(int, char**)
{
    const std::size_t sides[] = { 100, 200, 400, 800, 1200, 1600, 2000, 4000, 10000 };
    const std::size_t sidesCount = 9;
    const std::size_t iterations[] = { 1, 10, 30, 80, 150, 250, 500, 1000, 2000, 8000 };
    const std::size_t iterationsCount = 10;
    const ComplexRange ranges[] = {
        ComplexRange( Complex(-1.72, 1.2), Complex(1.0, -1.2) ),
        ComplexRange( Complex(-0.7, 0), Complex(0.3, -1) ),
        ComplexRange( Complex(-0.4, -0.5), Complex(0.1, -1) ),
        ComplexRange( Complex(-0.4, -0.6), Complex(-0.2, -0.8) ),
        ComplexRange( Complex(-0.24, -0.64), Complex(-0.26, -0.66) )
    };
    const std::size_t rangesCount = 5;

    #ifdef SAVE_IMAGE
    const std::size_t repetitions = 1;
    #else
    const std::size_t repetitions = 4;
    #endif

    for (std::size_t s = 0; s < sidesCount; ++s)
        for (std::size_t i = 0; i < iterationsCount; ++i)
            for (std::size_t r = 0; r < rangesCount; ++r)
                stats<Mandelbrot, void>(Mandelbrot(sides[s], iterations[i], ranges[r]), 
                                        iterations[i] >= 1000 && sides[s] >= 2000 ? 1 : repetitions);

    return 0;
}
