package workstealing

import scala.collection.workstealing._
import scala.collection.workstealing.benchmark._

// Imported from scala.collection.workstealing.benchmark.submissionsc13.scala
object Mandelbrot {

  def compute(xc: Double, yc: Double, threshold: Int): Int = {
    var i = 0
    var x = 0.0
    var y = 0.0
    while (x * x + y * y < 4 && i < threshold) {
      val xt = x * x - y * y + xc
      val yt = 2 * x * y + yc

      x = xt
      y = yt

      i += 1
    }
    i
  }

}

// Imported from scala.collection.workstealing.benchmark.submissionsc13.scala
object MandelbrotSpecific extends StatisticsBenchmark {

  val size = sys.props("size").toInt
  val threshold = sys.props("threshold").toInt
  val bounds = sys.props("bounds").split(",").map(_.toDouble)
  val image = new Array[Int](size * size)

  def run() {
    val range = new ParRange(0 until (size * size), Workstealing.DefaultConfig)
    val xlo = bounds(0)
    val ylo = bounds(1)
    val xhi = bounds(2)
    val yhi = bounds(3)

    for (idx <- range) {
      val x = idx % size
      val y = idx / size
      val xc = xlo + (xhi - xlo) * x / size
      val yc = ylo + (yhi - ylo) * y / size

      image(idx) = Mandelbrot.compute(xc, yc, threshold)
    }
  }

}


// Imported from scala.collection.workstealing.benchmark.submissionsc13.scala
object MandelbrotPC extends StatisticsBenchmark {

  val size = sys.props("size").toInt
  val threshold = sys.props("threshold").toInt
  val bounds = sys.props("bounds").split(",").map(_.toDouble)
  val image = new Array[Int](size * size)

  val parlevel = sys.props("par").toInt
  val fj = new collection.parallel.ForkJoinTaskSupport(new scala.concurrent.forkjoin.ForkJoinPool(parlevel))

  def run() {
    val range = (0 until (size * size)).par
    range.tasksupport = fj
    val xlo = bounds(0)
    val ylo = bounds(1)
    val xhi = bounds(2)
    val yhi = bounds(3)

    for (idx <- range) {
      val x = idx % size
      val y = idx / size
      val xc = xlo + (xhi - xlo) * x / size
      val yc = ylo + (yhi - ylo) * y / size

      image(idx) = Mandelbrot.compute(xc, yc, threshold)
    }
  }

}


/* Code below is imported from Madelbrot.scala, with a few modifications  */

case class ComplexRange(val first_r: Double, val first_i: Double, val second_r: Double, val second_i: Double) {
  override def toString(): String =  "{ (" + first_r + ";" + first_i + ") ; (" + second_r + ";" + second_i + ") }"  
}

case class MandelbrotMAGenerator(val width: Int, val height: Int, 
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

object MandelbrotMASpecific extends StatisticsBenchmark {

  val side = sys.props("size").toInt
  val maxIteration = sys.props("threshold").toInt
  val bounds = sys.props("bounds").split(",").map(_.toDouble)
  val range = ComplexRange(bounds(0), bounds(1), bounds(2), bounds(3))
  val inSet = 0x000000
  val notInSet = 0xffffff
  val image = new Array[Int](side * side)

  def run() {
    // Generate an image of the Mandelbrot set
    val indexes = new ParRange(0 until (side * side), Workstealing.DefaultConfig)

    val generator = MandelbrotMAGenerator(side, side, range, maxIteration, inSet, notInSet)
    val img = Array.ofDim[Int](side * side) 
    indexes foreach { idx =>
      img(idx) = generator.computeElement(idx)
    }
  }

}

object MandelbrotMAPC extends StatisticsBenchmark {

  val side = sys.props("size").toInt
  val maxIteration = sys.props("threshold").toInt
  val bounds = sys.props("bounds").split(",").map(_.toDouble)
  val range = ComplexRange(bounds(0), bounds(1), bounds(2), bounds(3))
  val inSet = 0x000000
  val notInSet = 0xffffff
  val image = new Array[Int](side * side)

  val parlevel = sys.props("par").toInt
  val fj = new collection.parallel.ForkJoinTaskSupport(new scala.concurrent.forkjoin.ForkJoinPool(parlevel))

  def run() {
    // Generate an image of the Mandelbrot set
    val indexes = (0 until side * side).par
    indexes.tasksupport = fj

    val generator = MandelbrotMAGenerator(side, side, range, maxIteration, inSet, notInSet)
    val img = Array.ofDim[Int](side * side) 
    indexes foreach { idx =>
      img(idx) = generator.computeElement(idx)
    }
  }

}

