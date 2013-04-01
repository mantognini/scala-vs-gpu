import org.scalameter.api._
import scala.util.{ Random }
import scala.collection.parallel.immutable.{ ParSeq }
import scala.collection.{ GenSeq }

case class CSVReporter() extends Reporter {
    def report(results: org.scalameter.utils.Tree[org.scalameter.CurveData],
               persistor: org.scalameter.Persistor) {

        // Nothing here

    }

    def report(result: org.scalameter.CurveData,
               persistor: org.scalameter.Persistor) {
        println("::Benchmark " + result.context.scope + "::")
        for (measurement <- result.measurements) {
            println(measurement.params.axisData.values.mkString(",") + "," + measurement.time)
        }
    }
}


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
        CSVReporter()
    )

    lazy val persistor = Persistor.None

    trait Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A]
    }

    object SequentialFiller extends Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A] = Seq.fill[A](count)(f)
    }

    object ParallelFiller extends Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A] = ParSeq.fill[A](count)(f)
    }

    def computeRatio(pointCount: Int): Double = computeRatioGeneric(SequentialFiller)(pointCount)

    def computeRatioParallel(pointCount: Int): Double = computeRatioGeneric(ParallelFiller)(pointCount)

    def computeRatioGeneric[T <: Filler](filler: T)(pointCount: Int): Double = {
        // Create two uniform random number generators
        val gX = Random
        val gY = Random
        def randomPoint: (Double, Double) = (gX.nextDouble, gY.nextDouble)

        // Create some random point in the square
        val points = filler.fill(pointCount)(randomPoint)

        // Count point inside the circle
        val pointInCircleCount = points count { case (x, y) => x * x + y * y <= 1 }

        // π/4 = .785398163
        val ratio = pointInCircleCount.toDouble / pointCount.toDouble

        ratio
    }

    val lowCounts = Gen.exponential("point count")(128, 32768, 2) // From 2^7 to 2^15
    val highCounts = Gen.range("point count")(65536, 4194304, 524288) // From 2^16 to 2^22 in ~8 steps

    performance of "MonteCarlo" config(exec.maxWarmupRuns -> 10) in {
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
                using(highCounts) in { pointCount => computeRatio(pointCount) }
            }

            measure method "computeRatioParallel" in {
                using(highCounts) in { pointCount => computeRatioParallel(pointCount) }
            }
        }
    }
}


