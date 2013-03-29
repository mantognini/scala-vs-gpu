import benchmark.{ TicToc }
import scala.util.{ Random }

object MonteCarlo extends TicToc {

	// Generate a random number in [0; max[
    def uniformDouble(generator: Random, max: Double): Double = generator.nextDouble * max

    def main(args: Array[String]): Unit = {
    	// TODO change TicToc to Scalameter for this benchmark

        val pointCount: Int = 50000
        val radius: Double = 20.0

        // Create two uniform random number generators
        val gX = Random
        val gY = Random
        def generatorX = uniformDouble(gX, radius)
        def generatorY = uniformDouble(gY, radius)
        def randomPoint: (Double, Double) = (generatorX, generatorY)

        tic

        // Create some random point in the square
        val points = 0 until pointCount map { _ => randomPoint }

        // Count point inside the circle
        val pointInCircleCount = points count { case (x, y) => x * x + y * y <= radius * radius }

        // π/4 = .785398163
        val ratio = pointInCircleCount.toDouble / pointCount.toDouble

        toc("Scala MonteCarlo Sequencial, " + pointCount)
        writeTimesLog()

        println("π is approximately " + (ratio * 4))
    }
}


