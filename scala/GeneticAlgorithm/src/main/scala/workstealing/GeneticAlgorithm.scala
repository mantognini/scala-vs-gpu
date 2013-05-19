package workstealing

import scala.collection.workstealing._
import scala.collection.workstealing.benchmark._

trait Population[Entity] {
  // PUBLIC API

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
      ???

      // Step 5.
      // -------
      //
      // Create CO new individuals with CrossOver

      // Replace the last CO entities before the N last ones (see comment at step 3)
      ???

      // Step 6.
      // -------
      //
      // Generate N new individuals randomly

      // Replace the last N entities (see comment at step 3)
      ???

      // Step 7.
      // -------
      //
      // Evaluate the current population

      // The evaluation of new entities was already done in step 3 to 6
      // So we only sort the population
      ???

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
    ???
  }

  // API TO IMPLEMENT IN CONCREATE POPULATION

  type Real = Double
  type EntityFitness = (Entity, Real)
  type Pop = Array[EntityFitness]

  def generator(): Entity
  def evaluator(e: Entity): Real
  def crossover(a: Entity, b: Entity): Entity
  def mutator(e: Entity): Entity

  def terminator(pop: Pop): Boolean
}

object GeneticAlgorithmBenchmark extends StatisticsBenchmark {

  def run() {
    ???
  }

}

