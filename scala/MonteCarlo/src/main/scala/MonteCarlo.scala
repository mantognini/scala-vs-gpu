import org.scalameter.api._
import scala.util.{ Random }

object MonteCarlo extends PerformanceTest {
    /* configuration */
    lazy val executor = LocalExecutor(
        Executor.Warmer.Default(),
        Aggregator.min,
        new Measurer.Default
    )
    /*SeparateJvmsExecutor(
        Executor.Warmer.Default(),
        Aggregator.min,
        new Measurer.Default
    )*/
    lazy val reporter = new LoggingReporter
    lazy val persistor = Persistor.None

    // List of results
    var results = List.empty[(Int, Double)] /* (point count, π/4 approximation) */

    val counts = Gen.exponential("point counts")(128, 4194304, 2)

    performance of "Monte Carlo π/4" in {
        using(counts) in { pointCount =>
            // Create two uniform random number generators
            val gX = Random
            val gY = Random
            def randomPoint: (Double, Double) = (gX.nextDouble, gY.nextDouble)

            // Create some random point in the square
            val points = 0 until pointCount map { _ => randomPoint }

            // Count point inside the circle
            val pointInCircleCount = points count { case (x, y) => x * x + y * y <= 1 }

            // π/4 = .785398163
            val ratio = pointInCircleCount.toDouble / pointCount.toDouble

            results = (pointCount, ratio) :: results
        }
    }

    println("Results:\n" + results.map{ case (c, a) => c + " ~> " + a}.mkString("\n"))
}


