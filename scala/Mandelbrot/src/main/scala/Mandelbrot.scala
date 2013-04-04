import scala.math.{ sqrt }
import java.awt.image.{ BufferedImage }
import java.io.{ File }
import javax.imageio.{ ImageIO }

// Minimal complex class for this application
case class Complex(val r: Double, val i: Double) {
    def *(z: Complex) = Complex(r * z.r - i * z.i, r * z.i + i * z.r)

    def +(z: Complex) = Complex(r + z.r, i + z.i)

    def abs: Double = sqrt(r * r + i * i)

    override def toString(): String = "(" + r + "; " + i + ")"
}

case class ComplexRange(val first: Complex, val second: Complex) {
    override def toString(): String =  "{ " + first + "; " + second + " }"  
}

case class Color(val rgb: Int)

case class Mandelbrot(val width: Int, val height: Int, 
                      val range: ComplexRange, val maxIteration: Int, 
                      val inSet: Color, val notInSet: Color) {
    def computeElement(index: Int): Color = {
        val x = index % width
        val y = index / height

        val c = Complex(
            range.first.r + x / (width - 1.0) * (range.second.r - range.first.r),
            range.first.i + y / (height - 1.0) * (range.second.i - range.first.i)
        )

        var z = Complex(0, 0)

        var iter = 0
        while (iter < maxIteration && z.abs < 2.0) {
            z = z * z + c
            iter = iter + 1
        }

        if (iter == maxIteration) inSet
        else notInSet
    }
}

object Mandelbrot {

    def main(args: Array[String]): Unit = {

        val sides = List( 100, 200, 400, 800, 1200, 1600, 2000, 4000, 10000 )
        val iterations = List( 1, 10, 30, 80, 150, 250, 500, 1000, 2000, 8000 )
        val ranges = List(
            ComplexRange( Complex(-1.72, 1.2), Complex(1.0, -1.2) ),
            ComplexRange( Complex(-0.7, 0), Complex(0.3, -1) ),
            ComplexRange( Complex(-0.4, -0.5), Complex(0.1, -1) ),
            ComplexRange( Complex(-0.4, -0.6), Complex(-0.2, -0.8) ),
            ComplexRange( Complex(-0.24, -0.64), Complex(-0.26, -0.66) )
        )

        val inSet = Color(0x000000)
        val notInSet = Color(0xffffff)

        var imgId = 0;

        for(side <- sides
            maxIteration <- iterations
            range <- ranges) {

            // Clean the VM
            System.gc()

            // Start timer
            val tic = System.nanoTime()

            //// COMPUTATION STARTS HERE

            val indexes = 0 until (side * side)

            val generator = Mandelbrot(side, side, range, maxIteration, inSet, notInSet)
            val img = indexes map generator.computeElement

            //// COMPUTATION ENDS HERE
            
            // Stop timer
            val toc = System.nanoTime();

            val µs = (toc - tic) / 1000

            val csvdescription = side + "," + maxIteration + "," + range
            
            println(csvdescription + "," + µs)

            val png = new BufferedImage(side, side, BufferedImage.TYPE_INT_RGB)
            for((index, color)  <- indexes zip img) {
                val x = index % side
                val y = index / side

                png.setRGB(x, y, color.rgb)
            }

            val outputfile = new File("tmp/fractal_" + imgId + "_" + csvdescription + ".png");
            ImageIO.write(png, "png", outputfile);
            imgId += 1
        }

        
    }
}