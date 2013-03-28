//
//  main.cpp
//  Mandelbrot
//
//  Created by Marco Antognini on 27/3/13.
//  Copyright (c) 2013 local. All rights reserved.
//

#include <iostream>
#include <utility>
#include <array>
#include <complex>
#include <SFML/Graphics.hpp>

namespace mb {

    typedef bool Color;
    typedef std::pair<int, int> ImageCoord;
    constexpr std::size_t WIDTH = 2000;
    constexpr std::size_t HEIGHT = 2000;
    typedef std::array<Color, HEIGHT * WIDTH> Image;
    Color& getPixel(Image& img, std::size_t x, std::size_t y)
    {
        return img[y * WIDTH + x];
    }

    typedef std::complex<double> Complex;

    typedef std::pair<Complex, Complex> ComplexRange;
    
    constexpr Color inSetColor = true;
    constexpr Color notInSetColor = false;
    
    Color computeElement(ImageCoord const& coord, std::size_t maxIterations, ComplexRange const& range)
    {
        Complex c {
            range.first.real() + coord.first / (WIDTH - 1.0) * (range.second.real() - range.first.real()),
            range.first.imag() + coord.second / (HEIGHT - 1.0) * (range.second.imag() - range.first.imag())
        };

        Complex z = { 0, 0 };

        std::size_t iter = 0;
        for (iter = 0; iter < maxIterations && std::abs(z) < 2.0; ++iter) {
            z = z * z + c;
        }

        return iter == maxIterations ? inSetColor : notInSetColor;
    }

    void computeImage(Image& img, std::size_t maxIterations, ComplexRange const& range)
    {
        for (std::size_t x = 0; x < WIDTH; ++x) {
            for (std::size_t y = 0; y < HEIGHT; ++y) {
                getPixel(img, x, y) = computeElement({x, y}, maxIterations, range);
            }
        }
    }
}

std::ostream& operator<<(std::ostream& out, sf::Time const& t)
{
    sf::Int64 micros = t.asMicroseconds();
    return out << micros << "µs";
}

int main(int argc, const char * argv[])
{
    sf::Clock clk;
    mb::Image img;
    std::size_t iterations = 1000;
    mb::ComplexRange range = { mb::Complex(-1.72, 1.2), mb::Complex(1.0, -1.2) };
    mb::computeImage(img, iterations, range);
    auto const time = clk.restart();

    std::cout << "fractal computed in " << time << std::endl;

    sf::Image png; png.create(mb::WIDTH, mb::HEIGHT, sf::Color::White);

    for (std::size_t x = 0; x < mb::WIDTH; ++x) {
        for (std::size_t y = 0; y < mb::HEIGHT; ++y) {
            if (mb::getPixel(img, x, y) == mb::inSetColor) png.setPixel(x, y, sf::Color::Black);
        }
    }

    png.saveToFile("fractal.png");

    return 0;
}

