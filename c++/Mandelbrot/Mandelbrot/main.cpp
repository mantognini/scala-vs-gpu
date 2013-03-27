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

//template<typename ColorType, typename ImageType>
//void draw_Mandelbrot(ImageType& image,                                   //where to draw the image
//                     ColorType set_color, ColorType non_set_color,       //which colors to use for set/non-set points
//                     double cxmin, double cxmax, double cymin, double cymax,//the rect to draw in the complex plane
//                     unsigned int max_iterations)                          //the maximum number of iterations
//{
//    std::size_t const ixsize = get_first_dimension(ImageType);
//    std::size_t const iysize = get_first_dimension(ImageType);
//    for (std::size_t ix = 0; ix < ixsize; ++ix)
//        for (std::size_t iy = 0; iy < iysize; ++iy)
//        {
//            std::complex<double> c(cxmin + ix/(ixsize-1.0)*(cxmax-cxmin), cymin + iy/(iysize-1.0)*(cymax-cymin));
//            std::complex<double> z = 0;
//            unsigned int iterations;
//
//            for (iterations = 0; iterations < max_iterations && std::abs(z) < 2.0; ++iterations)
//                z = z*z + c;
//
//            image[ix][iy] = (iterations == max_iterations) ? set_color : non_set_color;
//            
//        }
//}

namespace mb {

    typedef bool Color;
    typedef std::pair<int, int> ImageCoord;
    constexpr std::size_t WIDTH = 2000;
    constexpr std::size_t HEIGHT = 2000;
    typedef std::array<Color, WIDTH> Row;
    typedef std::array<Row, HEIGHT> Image;

    typedef std::complex<double> Complex;

    typedef std::pair<Complex, Complex> ComplexRange;
    
    constexpr Color inSetColor = true;
    constexpr Color notInSetColor = false;
    
    Color computeElement(ImageCoord const& coord, std::size_t maxIterations, ComplexRange const& range)
    {
        Complex c {
            range.first.real() + coord.first / (WIDTH - 1.0) * (range.second.real() - range.first.real()),
            range.first.imag() + coord.second / (WIDTH - 1.0) * (range.second.imag() - range.first.imag())
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
        for (std::size_t x = 0; x < img.size(); ++x) {
            for (std::size_t y = 0; y < img[x].size(); ++y) {
                img[x][y] = computeElement({x, y}, maxIterations, range);
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
    mb::Image img;
    std::size_t iterations = 1000;
    mb::ComplexRange range = { mb::Complex(-1.72, 1.2), mb::Complex(1.0, -1.2) };

    sf::Clock clk;
    mb::computeImage(img, iterations, range);
    auto const time = clk.restart();

    std::cout << "fractal computed in " << time << std::endl;

    sf::Image png; png.create(mb::WIDTH, mb::HEIGHT, sf::Color::White);

    for (std::size_t x = 0; x < img.size(); ++x) {
        for (std::size_t y = 0; y < img[x].size(); ++y) {
            if (img[x][y] == mb::inSetColor) png.setPixel(x, y, sf::Color::Black);
        }
    }

    png.saveToFile("fractal.png");

    return 0;
}

