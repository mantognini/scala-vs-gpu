import scala.math.{ sqrt }
import java.awt.image.{ BufferedImage }
import java.io.{ File }
import javax.imageio.{ ImageIO }
import benchmark.{ TicToc }

// Minimal complex class for this application
case class Complex(val r: Double, val i: Double) {
	def *(z: Complex) = Complex(r * z.r - i * z.i, r * z.i + i * z.r)

	def +(z: Complex) = Complex(r + z.r, i + z.i)

	def abs: Double = sqrt(r * r + i * i)

	override def toString(): String = "(" + r + ", " + i + ")"
	
}

case class ComplexRange(val first: Complex, val second: Complex) {
	override def toString(): String =  "{ " + first + ", " + second + " }" 
	
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

object Mandelbrot extends TicToc {

	def main(args: Array[String]): Unit = {
		// Start timer
		tic

  		val WIDTH = 2000
  		val HEIGHT = 2000
  		val iterations = 1000
  		val range = ComplexRange(Complex(-1.72, 1.2), Complex(1.0, -1.2))
  		val inSet = Color(0x000000)
  		val notInSet = Color(0xffffff)

  		val indexes = 0 until (HEIGHT * WIDTH)

  		val generator = Mandelbrot(WIDTH, HEIGHT, range, iterations, inSet, notInSet)
  		val img = indexes map generator.computeElement
  		
  		toc("Scala Mandelbrot Sequencial, " + WIDTH + 'x' + HEIGHT + ", " + range)
  		writeTimesLog()

  		val png = new BufferedImage(WIDTH, HEIGHT, BufferedImage.TYPE_INT_RGB)
  		for((index, color)  <- indexes zip img) {
			val x = index % WIDTH
			val y = index / HEIGHT

			png.setRGB(x, y, color.rgb)
  		}

  		val outputfile = new File("results/fractal.png");
    	ImageIO.write(png, "png", outputfile);
	}
}