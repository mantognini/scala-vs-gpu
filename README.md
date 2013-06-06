# Scala Parallel Collections VS GPU Frameworks

Bachelor Semester Project under the supervision of LAMP at EPFL

Marco Antognini, Sprint 2013


## Abstract

The objectives of this bachelor project are multiple. First, it aims to identify the currently available technologies to perform heavy computation like clusters of servers but also more compact computational devices like GPUs.The second objective is to implement a few benchmark applications to compare the performance – that is, the processing time but also more subjective metrics like the number of code line or the implementation cost in manpower – of a GPU framework and the parallel collections of Scala that work on CPUs.The selected GPU framework is Thrust, developed by NVIDIA on top of CUDA. Alternatively, this document also presents other technologies like Microsoft's C++AMP and uses very quickly TBB, a C++ framework for parallel computation developed by Intel.A subsidiary point approached by this paper is the comparison of performance between the current parallel collections of Scala and the underdevelopment Workstealing framework.This project concludes that GPU implementations are definitely much faster for short and easy algorithms but for bigger problems the use of GPU computational device is much harder, takes longer to develop and is not always faster. It also looks for future developments opportunities for Scala.

