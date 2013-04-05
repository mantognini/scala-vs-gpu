import org.scalameter.api._
import scala.util.{ Random }
import scala.collection.parallel.immutable.{ ParSeq }
import scala.collection.{ GenSeq }
import java.io.{ BufferedWriter, FileWriter, File }

case class CSVReporter(filename: String = "data.csv") extends Reporter {
    val file = new File(filename)
    file.delete()

    def report(results: org.scalameter.utils.Tree[org.scalameter.CurveData],
               persistor: org.scalameter.Persistor) {

        // Nothing here
    }

    def report(result: org.scalameter.CurveData,
               persistor: org.scalameter.Persistor) {

        val out = new BufferedWriter(new FileWriter(file, true))
        for (measurement <- result.measurements) {
            out.write(result.context.scope + "," + 
                      measurement.params.axisData.values.mkString(",") + "," + 
                      (measurement.time * 1000).toInt) // convert ms to µs
            out.newLine()
        }
        out.close()
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
        CSVReporter(),
        LoggingReporter()
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

    val counts = Gen.exponential("point count")(128, 4194304, 2) // From 2^7 to 2^22

    performance of "sequential" in {
        using(counts) in { pointCount => computeRatio(pointCount) }
    }

    performance of "parallel" in {
        using(counts) in { pointCount => computeRatioParallel(pointCount) }
    }
}


