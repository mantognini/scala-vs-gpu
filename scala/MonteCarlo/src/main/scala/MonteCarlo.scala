import org.scalameter.api._
import scala.util.{ Random }
import scala.collection.parallel.immutable.{ ParSeq, ParRange, ParVector }
import scala.collection.parallel.mutable.{ ParArray }
import scala.collection.{ GenSeq }
import scala.reflect.{ ClassTag }
import java.io.{ BufferedWriter, FileWriter, File }
import java.lang.{ Runtime }

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

case class TaskSupport(val level: Int) {
  val fjOpt = 
    if (level > 0) 
    	Some(new collection.parallel.ForkJoinTaskSupport(new scala.concurrent.forkjoin.ForkJoinPool(level)))
    else
    	None
  
  override def toString() = level.toString
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
//        ChartReporter(ChartFactory.XYLine()), 
        CSVReporter(),
        LoggingReporter()
    )

    lazy val persistor = Persistor.None
    
    def computeRatioParallel(pointCount: Int, parallelismLevel: Int, outerpar: Option[collection.parallel.ForkJoinTaskSupport]): Double = {
    	// Config
        val iterCount = pointCount / Math.min(parallelismLevel, pointCount)
        
        val gens1 = for (i <- 0 until parallelismLevel) yield {
          val genx = new Random()
          val geny = new Random()
          (genx,geny)
	    }
	
	    val gens /*: GenSeq[(Random, Random)] with Immutable */ = outerpar match {
	      case None => gens1
	      case Some(fj) =>
	        val p = gens1.par
	        p.tasksupport = fj
	        p
	    }
        
        val insideCount = gens.aggregate(0.0)({
		  (acc, genxy) => {
		    val range = 0 until iterCount
		    
		    val inside = range.count {
		      i =>
		        val x = genxy._1.nextDouble
		        val y = genxy._2.nextDouble
		        
		        x * x + y * y <= 1.0
		    }
		    
		    acc + inside
		  }
		},
		_ + _)
        
        // Compute the average
        val π = 4.0 * insideCount / pointCount

        π
    }
    
    val counts = Gen.exponential("point count")(128, 4194304, 2) // From 2^7 to 2^22
    val parallelisms = Gen.exponential("parallelism level")(1, 1024, 2)
	val outerpars = Gen.enumeration("outer parallelism")(
	    TaskSupport(0),
	    TaskSupport(2),
	    TaskSupport(4),
	    TaskSupport(6),
	    TaskSupport(8)
	)

    val params = for {
      count <- counts
      parallelism <- parallelisms
      outerpar <- outerpars
    } yield {
      (count, parallelism, outerpar)
    }

    performance of "montecarlo" in {
        using(params) in { case (pointCount, parallelismLevel, outerpar) => 
          	computeRatioParallel(pointCount, parallelismLevel, outerpar.fjOpt) 
        }
    }
}


