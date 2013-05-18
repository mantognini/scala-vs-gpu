package workstealing

import scala.collection.workstealing._
import scala.collection.workstealing.benchmark._

trait Population[Entity] {
  // PUBLIC API

  def run(size: Int, K: Int, M: Int, N: Int, CO: Int): Entity = {
    ???
  }

  // API TO IMPLEMENT IN CONCREATE POPULATION

  type Real = Double
  type EntityFitness = (Entity, Real)
  type Pop = ParArray[EntityFitness]

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

