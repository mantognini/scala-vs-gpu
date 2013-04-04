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
    std::size_t maxIterations = 1000;
    std::size_t side = 2000;
    ComplexRange range = { Complex(-1.72, 1.2), Complex(1.0, -1.2) };
    stats<Mandelbrot, void>(Mandelbrot(side, maxIterations, range), 1);

    return 0;
}

