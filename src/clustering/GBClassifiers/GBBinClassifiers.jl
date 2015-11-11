# *****************************************************************************
# Written by Ritchie Lee, ritchie.lee@sv.cmu.edu
# *****************************************************************************
# Copyright ã 2015, United States Government, as represented by the
# Administrator of the National Aeronautics and Space Administration. All
# rights reserved.  The Reinforcement Learning Encounter Simulator (RLES)
# platform is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You
# may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable
# law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.
# _____________________________________________________________________________
# Reinforcement Learning Encounter Simulator (RLES) includes the following
# third party software. The SISLES.jl package is licensed under the MIT Expat
# License: Copyright (c) 2014: Youngjun Kim.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED
# "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# *****************************************************************************

#Grammar-Based Classifier
module GBClassifers

export BestSampleParams, best_sample, GeneticSearchParams, genetic_search

using GrammaticalEvolution
import GrammaticalEvolution.evaluate!

immutable BestSampleParams
  grammar::Grammar
  genome_size::Int64
  maxvalue::Int64
  maxwraps::Int64
  default_code::Expr
  get_fitness::Function
end

immutable GeneticSearchParams
  grammar::Grammar
  genome_size::Int64
  pop_size::Int64
  maxwraps::Int64
  default_code::Expr
  max_fitness::Float64
  get_fitness::Function
end

function best_sample(p::BestSampleParams, nsamples::Int64; verbosity::Int64=0)
  best_ind = ExampleIndividual(p.genome_size, p.maxvalue) #maxvalue=1000
  best_ind.fitness = Inf
  labels = "empty"
  for i = 1:nsamples
    ind = ExampleIndividual(p.genome_size, p.maxvalue)
    evaluate!(p.grammar, ind, p.maxwraps, p.get_fitness, p.default_code)
    if verbosity > 1
      s1 = string(best_ind.code)
      s2 = take(s1, 50) |> join
      println("$i: fitness=$(ind.fitness), best=$(best_ind.fitness), length=$(length(s1)), code=$(s2)")
    end
    if 0.0 < ind.fitness < best_ind.fitness
      best_ind = ind
    end
  end
  if verbosity > 0
    s1 = string(best_ind.code)
    s2 = take(s1, 50) |> join
    println("best: fitness=$(best_ind.fitness), length=$(length(s1)), code=$(s2)")
  end
  return best_ind
end

function evaluate!(grammar::Grammar, ind::ExampleIndividual, maxwraps::Int64, get_fitness::Function, default_code::Expr)
  try
    ind.code = transform(grammar, ind, maxwraps=maxwraps)
    ind.fitness = get_fitness(ind.code)
  catch e
    if !isa(e, MaxWrapException)
      s = take(string(e), 50) |> join
      println("exception = $s")
      s = take(string(ind.code), 50) |> join
      println("code: $(s)")
    end
    ind.code = default_code
    ind.fitness = Inf
  end
end

function genetic_search(p::GeneticSearchParams, min_iters::Int64, max_iters::Int64; verbosity::Int=0)
  if verbosity > 0
    println("Starting search...")
  end
  pop = ExamplePopulation(p.pop_size, p.genome_size)
  fitness = Inf
  iter = 1
  while iter <= min_iters || (fitness > p.max_fitness && iter <= max_iters)
    # generate a new population (based off of fitness)
    pop = generate(p.grammar, pop, 0.1, 0.2, 0.2, p.maxwraps, p.get_fitness, p.default_code)
    fitness = pop[1].fitness #population is sorted, so first entry i the best
    s1 = string(pop[1].code)
    s2 = take(s1, 50) |> join
    if verbosity > 0
      println("generation: $iter, max fitness=$fitness, length=$(length(s1)) code=$(s2)")
    end
    iter += 1
  end
  return pop[1]
end

end #module


