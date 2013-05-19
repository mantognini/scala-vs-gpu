package workstealing

import scala.collection.workstealing._
import scala.collection.workstealing.benchmark._

import java.util.concurrent.{ ThreadLocalRandom }

trait Population[E] {
  // PUBLIC API
  
  type Entity = E

  def run(size: Int, K: Int, M: Int, N: Int, CO: Int): Entity = {
    // Step 0.
    // -------
    //
    // Make sure parameters are valid
    assert(size > 0, "invalid size parameter")
    assert(K >= 0 && K < size, "invalid K parameter")
    assert(M >= 0 && M < size, "invalid M parameter")
    assert(N >= 0 && CO >= 0 && N + CO == K, "invalid N or CO parameter")

    // Helpers
    def withFitness(entity: Entity) = (entity, evaluator(entity))

    // Step 1 + 2.
    // -----------
    //
    // Generate a population & evaluate it
    var pop = new Pop(size)
    new ParRange(0 until size, Workstealing.DefaultConfig) foreach {
      pop.update(_, withFitness(generator))
    }
    // Now sort it
    pop = pop sortWith { _._2 > _._2 } // use fitness to sort
    // TODO would ParRange.aggregate with a merge sort be better ? 
    // TODO or would java.util.Arrays.sort(T[], Comparator<T>) be better ?

    var rounds = 0;

    do {
      rounds += 1

      // Step 3.
      // -------
      //
      // Remove the worse K individuals

      // Skipped -> replace those entities with step 5 & 6

      // Step 4.
      // -------
      //
      // Mutate M individuals of the population

      // Choose M random individuals from the living ones, that is in range [0, size-K[
      val indexBegin = 0
      val indexEnd = size - K
      new ParRange(0 until M, Workstealing.DefaultConfig) foreach { n =>
        val index = ThreadLocalRandom.current.nextInt(indexBegin, indexEnd)
        // Hopefully, two index computed in parallel won't be the same.
        // (If that's the case, we don't care much)
        pop.update(index, withFitness(mutator(pop(index)._1)))
      }

      // Step 5.
      // -------
      //
      // Create CO new individuals with CrossOver

      // Replace the last CO entities before the N last ones (see comment at step 3)
      new ParRange(size - N - CO until size - N, Workstealing.DefaultConfig) foreach { n =>
        val first = ThreadLocalRandom.current.nextInt(indexBegin, indexEnd)
        val second = ThreadLocalRandom.current.nextInt(indexBegin, indexEnd)
        // CrossOver
        pop.update(n, withFitness(crossover(pop(first)._1, pop(second)._1)))
      }

      // Step 6.
      // -------
      //
      // Generate N new individuals randomly

      // Replace the last N entities (see comment at step 3)
      new ParRange(size - N until size, Workstealing.DefaultConfig) foreach { n =>
        pop.update(n, withFitness(generator))
      }

      // Step 7.
      // -------
      //
      // Evaluate the current population

      // The evaluation of new entities was already done in step 3 to 6
      // So we only sort the population
      pop = pop sortWith { _._2 > _._2 } // use fitness to sort

      // Step 8.
      // -------
      //
      // Goto Step 3 if the population is not stable yet
    } while (!terminator(pop))

    println("#Rounds : " + rounds)

    // Step 9.
    // -------
    //
    // Identify the best individual from the current population
    val max = pop(0)._1

    println("Max: " + max)

    max
  }

  // API TO IMPLEMENT IN CONCREATE POPULATION

  protected type Real = Double
  protected type EntityFitness = (Entity, Real)
  protected type Pop = Array[EntityFitness]

  protected def generator(): Entity
  protected def evaluator(e: Entity): Real
  protected def crossover(a: Entity, b: Entity): Entity
  protected def mutator(e: Entity): Entity

  protected def terminator(pop: Pop): Boolean
}

object EquationMaximizer extends Population[(Double, Double)] {
  private val MIN_X = 9
  private val MAX_X = 100
  private val MIN_Y = 7
  private val MAX_Y = 50

  override protected def generator = (
    ThreadLocalRandom.current.nextDouble(MIN_X, MAX_X),
    ThreadLocalRandom.current.nextDouble(MIN_Y, MAX_Y)
  )

  override protected def evaluator(xy: Entity) = {
    val (x, y) = xy
    Math.sin(x - 15) / x * (y - 7) * (y - 30) * (y - 50) * (x - 15) * (x - 45)
  }
  
  override protected def crossover(axy: Entity, bxy: Entity): Entity = {
    val (x1, y1) = axy
    val (x2, y2) = bxy
    
    ((x1 + x2) / 2, (y1 + y2) / 2)
  }

}

object GeneticAlgorithmBenchmark extends StatisticsBenchmark {

  val size = sys.props("size").toInt
  val K = sys.props("K").toInt
  val M = sys.props("M").toInt
  val N = sys.props("N").toInt
  val CO = sys.props("CO").toInt

  def run() {
    val max = EquationMaximizer.run(size, K, M, N, CO)
  }

}

