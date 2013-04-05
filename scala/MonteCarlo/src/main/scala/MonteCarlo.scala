import org.scalameter.api._
import scala.util.{ Random }
import scala.collection.parallel.immutable.{ ParSeq, ParRange, ParVector }
import scala.collection.parallel.mutable.{ ParArray }
import scala.collection.{ GenSeq }
import scala.reflect.{ ClassTag }
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

    object SequentialSeqFiller extends Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A] = Seq.fill[A](count)(f)
    }

    object ParallelSeqFiller extends Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A] = ParSeq.fill[A](count)(f)
    }

    object SequentialRangeFiller extends Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A] = Range(0, count, 1) map { _ => f }
    }

    object ParallelRangeFiller extends Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A] = ParRange(0, count, 1, false) map { _ => f }
    }

    // object SequentialArrayFiller extends Filler {
    //     def fill[A](count: Int)(f: => A): GenSeq[A] = Array.fill[A](count)(f)
    // }

    object ParallelArrayFiller extends Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A] = ParArray.fill[A](count)(f)
    }

    object SequentialVectorFiller extends Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A] = Vector.fill[A](count)(f)
    }

    object ParallelVectorFiller extends Filler {
        def fill[A](count: Int)(f: => A): GenSeq[A] = ParVector.fill[A](count)(f)
    }

    def computeRatioSeq(pointCount: Int): Double = computeRatioGeneric(SequentialSeqFiller)(pointCount)
    def computeRatioParallelSeq(pointCount: Int): Double = computeRatioGeneric(ParallelSeqFiller)(pointCount)
    def computeRatioRange(pointCount: Int): Double = computeRatioGeneric(SequentialRangeFiller)(pointCount)
    def computeRatioParallelRange(pointCount: Int): Double = computeRatioGeneric(ParallelRangeFiller)(pointCount)
    // def computeRatioArray(pointCount: Int): Double = computeRatioGeneric(SequentialArrayFiller)(pointCount)
    def computeRatioParallelArray(pointCount: Int): Double = computeRatioGeneric(ParallelArrayFiller)(pointCount)
    def computeRatioVector(pointCount: Int): Double = computeRatioGeneric(SequentialVectorFiller)(pointCount)
    def computeRatioParallelVector(pointCount: Int): Double = computeRatioGeneric(ParallelVectorFiller)(pointCount)

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

    performance of "seq.sequential" in {
        using(counts) in { pointCount => computeRatioSeq(pointCount) }
    }

    performance of "seq.parallel" in {
        using(counts) in { pointCount => computeRatioParallelSeq(pointCount) }
    }

    performance of "range.sequential" in {
        using(counts) in { pointCount => computeRatioRange(pointCount) }
    }

    performance of "range.parallel" in {
        using(counts) in { pointCount => computeRatioParallelRange(pointCount) }
    }

    // performance of "array.sequential" in {
    //     using(counts) in { pointCount => computeRatioArray(pointCount) }
    // }

    performance of "array.parallel" in {
        using(counts) in { pointCount => computeRatioParallelArray(pointCount) }
    }

    performance of "vector.sequential" in {
        using(counts) in { pointCount => computeRatioVector(pointCount) }
    }

    performance of "vector.parallel" in {
        using(counts) in { pointCount => computeRatioParallelVector(pointCount) }
    }
}


