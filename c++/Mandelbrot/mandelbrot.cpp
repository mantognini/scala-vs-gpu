#include <iostream>
#include <utility>
#include <vector>
#include <complex>
#include <cmath>
#include <sstream>
#include "stats.hpp"

#ifdef SAVE_IMAGE
    #include <SFML/Graphics.hpp>
#endif

// black or white
enum class Color : bool {
    WHITE = true,
    BLACK = false
};
constexpr Color inSetColor = Color::WHITE;
constexpr Color notInSetColor = Color::BLACK;

typedef double Real;

typedef std::complex<Real> Complex;

std::ostream& operator<<(std::ostream& out, Complex const& z)
{
    return out << "(" << z.real() << ";" << z.imag() << ")";
}

typedef std::pair<Complex, Complex> ComplexRange;

std::ostream& operator<<(std::ostream& out, ComplexRange const& range)
{
    return out << "{" << range.first << ";" << range.second << "}";
}

typedef std::vector<Color> Image; // square image stored in a 1D array

std::size_t getSideSize(Image const& img)
{
    return std::sqrt(img.size());
}

Color& getPixel(Image& img, std::size_t x, std::size_t y)
{
    return img[y * getSideSize(img) + x];
}

struct Mandelbrot
{
    Mandelbrot(std::size_t side, std::size_t maxIterations, ComplexRange range)
    : side(side)
    , maxIterations(maxIterations)
    , range(range)
    { /* - */ }

    // Perform the set computation
    void operator()() const
    {
        Image img(side * side);
        for (std::size_t x = 0; x < side; ++x) {
            for (std::size_t y = 0; y < side; ++y) {
                getPixel(img, x, y) = computeElement(x, y);
            }
        }

        #ifdef SAVE_IMAGE
        static std::size_t imgId = 0;
        sf::Image png; png.create(side, side, sf::Color::White);

        // Export it to png
        for (std::size_t x = 0; x < side; ++x) {
            for (std::size_t y = 0; y < side; ++y) {
                png.setPixel(x, y, getPixel(img, x, y) == inSetColor ? sf::Color::Black : sf::Color::White);
            }
        }

        png.saveToFile("tmp/fractal_" + std::to_string(imgId) + "_" + csvdescription() + ".png");
        ++imgId;
        #endif
    }
    
    std::string csvdescription() const 
    {
        std::stringstream ss;
        ss << side << "," 
           << maxIterations << "," 
           << range;
        return ss.str();
    }

    // Compute the color of one element of the set
    Color computeElement(std::size_t x, std::size_t y) const
    {
        const Complex c {
            range.first.real() + x / (side - 1.0) * (range.second.real() - range.first.real()),
            range.first.imag() + y / (side - 1.0) * (range.second.imag() - range.first.imag())
        };

        Complex z = { 0, 0 };

        std::size_t iter = 0;
        for (iter = 0; iter < maxIterations && std::abs(z) < 2.0; ++iter) {
            z = z * z + c;
        }

        return iter == maxIterations ? inSetColor : notInSetColor;
    }

    std::size_t side, maxIterations;
    ComplexRange range;
};


int main(int, const char**)
{
    const std::vector<std::size_t> sides = { 100, 200, 400, 800, 1200, 1600, 2000, 4000, 10000 };
    const std::vector<std::size_t> iterations = { 1, 10, 30, 80, 150, 250, 500, 1000, 2000, 8000 };
    const std::vector<ComplexRange> ranges = {
        { Complex(-1.72, 1.2), Complex(1.0, -1.2) },
        { Complex(-0.7, 0), Complex(0.3, -1) },
        { Complex(-0.4, -0.5), Complex(0.1, -1) },
        { Complex(-0.4, -0.6), Complex(-0.2, -0.8) },
        { Complex(-0.24, -0.64), Complex(-0.26, -0.66) }
    };

    #ifdef SAVE_IMAGE
    const std::size_t repetitions = 1;
    #else
    const std::size_t repetitions = 4;
    #endif

    for (auto const& side: sides)
        for (auto const& maxIterations: iterations)
            for (auto const& range: ranges)
                stats<Mandelbrot, void>({side, maxIterations, range}, (maxIterations >= 1000 && side >= 2000 ? 1 : repetitions));

    return 0;
}

