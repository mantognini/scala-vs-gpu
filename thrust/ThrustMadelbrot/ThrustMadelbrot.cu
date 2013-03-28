#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <thrust/sequence.h>

#include <SFML/Graphics.hpp>

#include "cuda_complex.hpp"
typedef complex<double> Complex;
typedef std::pair<Complex, Complex> ComplexRange;

typedef unsigned int Color;
typedef Color Index;
// Note : indexes are stored as color to reduce memory usage (we transform Indexes into Colors in place)

struct Mandelbrot : public thrust::unary_function<Index, Color> {
    std::size_t width, height;
    Color inSetColor, notInSetColor;
    ComplexRange range;
    std::size_t maxIterations;

    Mandelbrot(std::size_t width, std::size_t height, Color in, Color out, ComplexRange range, std::size_t maxIterations)
        : width(width), height(height), inSetColor(in), notInSetColor(out), range(range), maxIterations(maxIterations) {
        /* that's it */
    }

    __host__ __device__
    Color operator()(Index const& index) {
        const unsigned int x = index % width;
        const unsigned int y = index / height; // integer division

        Complex c(
            range.first.real() + x / (width - 1.0) * (range.second.real() - range.first.real()),
            range.first.imag() + y / (width - 1.0) * (range.second.imag() - range.first.imag())
        );

        Complex z( 0, 0 );

        std::size_t iter = 0;
        for (iter = 0; iter < maxIterations && abs(z) < 2.0; ++iter) {
            z = z * z + c;
        }

        return iter == maxIterations ? inSetColor : notInSetColor;
    }
};

int main(int argc, char** argv)
{
    const std::size_t WIDTH = 2000;
    const std::size_t HEIGHT = 2000;
    const Color inSet = 0xffffff;
    const Color notInSet = 0x000000;
    const ComplexRange range ( Complex(-1.72, 1.2), Complex(1.0, -1.2) );
    const std::size_t iterations = 1000;

    // Create an array on the device
    thrust::device_vector<Color> deviceImg(WIDTH * HEIGHT);

    // First, load all indexes into deviceImg
    thrust::sequence(deviceImg.begin(), deviceImg.end());

    // Then, transform the indexes into 'colors'
    thrust::transform(deviceImg.begin(), deviceImg.end(),
                      deviceImg.begin(),
                      Mandelbrot(WIDTH, HEIGHT, inSet, notInSet, range, iterations));

	// Copy the data to the host memory
    thrust::host_vector<Color> img(deviceImg.begin(), deviceImg.end());

    // Export it to png
    sf::Image png; png.create(WIDTH, HEIGHT, sf::Color::White);
    for (std::size_t x = 0; x < WIDTH; ++x) {
        for (std::size_t y = 0; y < HEIGHT; ++y) {
            if (img[y * WIDTH + x] == inSet) png.setPixel(x, y, sf::Color::Black);
        }
    }

    png.saveToFile("fractal.png");

    return 0;
}
