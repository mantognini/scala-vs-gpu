import java.awt.image.{ BufferedImage }
import java.io.{ File }
import javax.imageio.{ ImageIO }
import scala.collection.workstealing._

case class ComplexRange(val first_r: Double, val first_i: Double, val second_r: Double, val second_i: Double) {
    override def toString(): String =  "{ (" + first_r + ";" + first_i + ") ; (" + second_r + ";" + second_i + ") }"  
}

case class Mandelbrot(val width: Int, val height: Int, 
                      val range: ComplexRange, val maxIteration: Int, 
                      val inSet: Int, val notInSet: Int) {
    def computeElement(index: Int): Int = {
        val x = index % width
        val y = index / height

        val c_r = range.first_r + x / (width - 1.0) * (range.second_r - range.first_r)
        val c_i = range.first_i + y / (height - 1.0) * (range.second_i - range.first_i)

        var z_r, z_i = 0.0

        var iter = 0
        while (iter < maxIteration && z_r * z_r + z_i * z_i < 4.0) {
            // z = z * z + c
            val tmp = z_r;
            z_r = z_r * z_r - z_i * z_i + c_r
            z_i = 2 * tmp * z_i + c_i
            iter = iter + 1
        }

        if (iter == maxIteration) inSet
        else notInSet
    }
}

object Mandelbrot {

    def main(args: Array[String]): Unit = {

        val sides = List( 100, 400, 1200, 2000, 4000, 10000 )
        val iterations = List( 1, 30, 250, 1000, 2000, 8000 )
        val ranges = List(
            ComplexRange( -1.72, 1.2, 1.0, -1.2 ),
            ComplexRange( -0.7, 0, 0.3, -1 ),
            ComplexRange( -0.4, -0.5, 0.1, -1 ),
            ComplexRange( -0.4, -0.6, -0.2, -0.8 ),
            ComplexRange( -0.24, -0.64, -0.26, -0.66 )
        )

        val inSet = 0x000000
        val notInSet = 0xffffff

        var imgId = 0;
        
        val parlevel = sys.props("par").toInt
        val fj = new collection.parallel.ForkJoinTaskSupport(new scala.concurrent.forkjoin.ForkJoinPool(parlevel))

        type ComputeFn = (Int, Int, ComplexRange) => Array[Int]
        
        def stats(side: Int, maxIteration: Int, range: ComplexRange, title: String, compute: ComputeFn) {

            // Warmup
            if (side <= 500 || side <= 1000 && maxIteration < 2000) {
                for (i <- 0 until 20) {
                    compute(side, maxIteration, range)
                }
            }

            // Clean the VM
            System.gc()

            // Start timer
            val tic = System.nanoTime()

            //// COMPUTATION STARTS HERE

            val img = compute(side, maxIteration, range)

            //// COMPUTATION ENDS HERE
            
            // Stop timer
            val toc = System.nanoTime();

            val µs = (toc - tic) / 1000

            // Display the result
            val csvdescription = "parallel" + "," + side + "," + maxIteration + "," + range
            println(csvdescription + "," + µs)

            // Export the set to PNG
            val png = new BufferedImage(side, side, BufferedImage.TYPE_INT_RGB)
            val indexes = 0 until (side * side)
            for((index, color)  <- indexes zip img) {
                val x = index % side
                val y = index / side

                png.setRGB(x, y, color)
            }

            val outputfile = new File("tmp/fractal_" + imgId + "_" + csvdescription + ".png");
            ImageIO.write(png, "png", outputfile);

            imgId += 1
        }
        
        // Generate an image of the Mandelbrot set using the current parallel collection
        def computeNormal(side: Int, maxIteration: Int, range: ComplexRange): Array[Int] = {
            val indexes = (0 until side * side).par
            indexes.tasksupport = fj

            val generator = Mandelbrot(side, side, range, maxIteration, inSet, notInSet)
            val img = Array.ofDim[Int](side * side) 
            indexes foreach { idx =>
              img(idx) = generator.computeElement(idx)
            }

            img
        }
        
        // Generate an image of the Mandelbrot set using the next generation of parallel collection
        def computeNewPC(side: Int, maxIteration: Int, range: ComplexRange): Array[Int] = {
            val indexes = new ParRange(0 until (side * side), Workstealing.DefaultConfig)

            val generator = Mandelbrot(side, side, range, maxIteration, inSet, notInSet)
            val img = Array.ofDim[Int](side * side) 
            indexes foreach { idx =>
              img(idx) = generator.computeElement(idx)
            }

            img
        }

        for {
          side <- sides
          maxIteration <- iterations
          range <- ranges
        }{
            stats(side, maxIteration, range, "normal", computeNormal)
            stats(side, maxIteration, range, "newpc", computeNewPC)
        }
    }
}

