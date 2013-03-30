import org.scalameter.api._
import scala.util.{ Random }
import scala.collection.parallel.immutable.{ ParSeq }

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
    lazy val reporter = Reporter.Composite(
        ChartReporter(ChartFactory.XYLine()), 
        new LoggingReporter // TODO edit this logger to display π/4 approximations
    )
    lazy val persistor = Persistor.None

    def computeRatio(pointCount: Int): Double = {
        // Create two uniform random number generators
        val gX = Random
        val gY = Random
        def randomPoint: (Double, Double) = (gX.nextDouble, gY.nextDouble)

        // Create some random point in the square
        val points = Seq.fill(pointCount)(randomPoint)

        // Count point inside the circle
        val pointInCircleCount = points count { case (x, y) => x * x + y * y <= 1 }

        // π/4 = .785398163
        val ratio = pointInCircleCount.toDouble / pointCount.toDouble

        ratio
    }

    def computeRatioParallel(pointCount: Int): Double = {
        // Create two uniform random number generators
        val gX = Random
        val gY = Random
        def randomPoint: (Double, Double) = (gX.nextDouble, gY.nextDouble)

        // Create some random point in the square
        val points = ParSeq.fill(pointCount)(randomPoint)

        // Count point inside the circle
        val pointInCircleCount = points count { case (x, y) => x * x + y * y <= 1 }

        // π/4 = .785398163
        val ratio = pointInCircleCount.toDouble / pointCount.toDouble

        ratio
    }

    val lowCounts = Gen.exponential("point count")(128, 32768, 2) // From 2^7 to 2^15
    val highCounts = Gen.range("point count")(65536, 4194304, 131072) // From 2^16 to 2^22

    performance of "MonteCarlo" in {
        performance of "Low Count" in {
            measure method "computeRatio" in {
                using(lowCounts) in { pointCount => computeRatio(pointCount) }
            }

            measure method "computeRatioParallel" in {
                using(lowCounts) in { pointCount => computeRatioParallel(pointCount) }
            }
        }

        performance of "High Count" in {
            measure method "computeRatio" in {
                using(lowCounts) in { pointCount => computeRatio(pointCount) }
            }

            measure method "computeRatioParallel" in {
                using(lowCounts) in { pointCount => computeRatioParallel(pointCount) }
            }
        }
    }
}


