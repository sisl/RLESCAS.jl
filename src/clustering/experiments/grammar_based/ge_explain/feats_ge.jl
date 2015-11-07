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

include(Pkg.dir("RLESCAS/src/clustering/clustering.jl"))
include(Pkg.dir("RLESCAS/src/clustering/experiments/grammar_based/grammar.jl"))

using DataFrameSets
using ClusterResults
using RLESUtils.FileUtils
using Iterators
using DataFrames
using GrammaticalEvolution

const DF_DIR = Pkg.dir("RLESCAS/src/clustering/data/dasc_nmacs_ts_feats/")
const GRAMMAR = create_grammar()
const W1 = 0.0001 #code length
const GENOME_SIZE = 500
const POP_SIZE = 10000
const MAXWRAPS = 2
const N_ITERATIONS = 5

function GrammaticalEvolution.evaluate!(grammar::Grammar, ind::ExampleIndividual, Dsl::DFSetLabeled)
  predicted_labels = nothing
  try
    ind.code = transform(grammar, ind, maxwraps=MAXWRAPS)
    @eval fn(D) = $(ind.code)
    predicted_labels = map(fn, Dsl.records)
  catch e
    if !isa(e, MaxWrapException)
      println("exception = $e")
      println("code: $(ind.code)")
    end
    ind.code = :(throw($e))
    ind.fitness = Inf
    return
  end
  accuracy = count(identity, predicted_labels .== Dsl.labels) / length(Dsl)
  if 0.0 <= accuracy < 0.5
    ind.code = negate_expr(ind.code)
    accuracy = 1.0 - accuracy
  end
  err = 1.0 - accuracy
  #ind.fitness = err + W1*length(string(ind.code)) + W2*rand()
  ind.fitness = err > 0.0 ? err : W1 * length(string(ind.code))
end

negate_expr(ex::Expr) = parse("!($ex)")

function learn_rule(Dsl::DFSetLabeled, n_iterations::Int64=N_ITERATIONS,
                    grammar::Grammar=GRAMMAR, pop_size::Int64=POP_SIZE,
                    genome_size::Int64=GENOME_SIZE, maxwraps::Int64=MAXWRAPS)
  println("learn_rule...")
  pop = ExamplePopulation(pop_size, genome_size)
  generation = 1
  while generation <= n_iterations
    # generate a new population (based off of fitness)
    pop = generate(grammar, pop, 0.1, 0.2, 0.2, Dsl)

    # population is sorted, so first entry it the best
    fitness = pop[1].fitness
    println("generation: $generation, max fitness=$fitness, code=$(pop[1].code)")
    generation += 1
  end
  ind = pop[1]
  @eval f(D) = $(ind.code)
  pred = map(f, Dsl.records)
  code = sub_varnames(string(ind.code), get_colnames(Dsl))
  println("code=$code")
  return (f, ind, pred, code)
end

function direct_sample(Ds::DFSet, labels::Vector{Bool}, genome_size::Int64, nsamples::Int64)
  grammar = create_grammar()
  best_ind = ExampleIndividual(genome_size, 1000)
  best_ind.fitness = Inf
  for i = 1:nsamples
    ind = ExampleIndividual(genome_size, 1000)
    evaluate!(grammar, ind, Ds, labels)
    s = string(ind.code)
    l = min(length(s), 50)
    println("$i: fitness=$(ind.fitness), best=$(best_ind.fitness), length=$(length(s)), code=$(s[1:l])")
    if 0.0 < ind.fitness < best_ind.fitness
      best_ind = ind
    end
  end
  return best_ind
end

function fill_to_col!{T}(Ds::DFSet, field_id::Int64, fillvals::AbstractVector{T})
  @assert length(Ds) == length(fillvals)
  for i = 1:length(Ds)
    fill!(Ds[i].columns[field_id], fillvals[i])
  end
end

function script1()
  Ds, labels = get_Ds(0,2)
  fill_to_col!(Ds, 1, !labels)
  #should give: all(!D[:,1])
  (f, ind, pred) = learn_rule(Ds, labels)
end

function script2()
  Ds, labels = get_Ds(0,2)
  fill_to_col!(Ds, 2, map(x -> x ? 25.0 : -5.0, labels))
  #should give: all(0.0 .<= D[:,2])
  (f, ind, pred) = learn_rule(Ds, labels)
end

#=
function samedir_firstRA!(Ds::DFSet, labels::Vector{Bool})
  vert_rate1, alarm1, resp_none1, target_rate1 = map(x -> Ds[1].colindex[x], [:vert_rate_1, :alarm_1, :response_none_1, :target_rate_1])
  for i = 1:length(Ds)
    col = Ds[i].columns
    for j = 1:length(col[vert_rate1])
      if col[alarm1][j] && col[resp_none1][j] #first RA
        s = sign(col[target_rate1][j])
        if s == 0.0
          col[vert_rate1][j] = labels[i] ? 0.0 : -1.0
        else #s not zero
          z = s * (abs(col[vert_rate1][j]) + 1.0) #same sign as target_rate_1, avoid 0.0 on vert_rate
          col[vert_rate1][j] = labels[i] ? z : -z
        end
      end
    end
  end
  #should give: Y(D[:,alarm1] && D[:,resp_none1], sn(D[:,:target_rate1], D[:,:vert_rate1]))
  #should give: Y(D[:,24] && D[:,30], sn(D[:,22], D[:,2]))
end

function script4()
  Ds, labels = get_Ds(1, 4)
  samedir_firstRA!(Ds, labels)
  #should give: Y(D[:,alarm1] && D[:,resp_none1], sn(D[:,:target_rate1], D[:,:vert_rate1]))
  #should give: Y(D[:,24] && D[:,30], sn(D[:,22], D[:,2]))
  (f, ind, pred) = learn_rule(Ds, labels)
end

function script5()
  Ds, labels = get_Ds(0, 2)
  samedir_firstRA!(Ds, labels)
  direct_sample(Ds, labels, 500, 100000)
end
=#

function get_name2file_map() #maps encounter number to filename
  df_files = readdir_ext("csv", DF_DIR)
  ks = map(df_files) do f
    s = basename(f)
    s = replace(s, "trajSaveMCTS_ACASX_EvE_", "")
    return replace(s, "_dataframe.csv", "")
  end
  name2file_map = Dict{ASCIIString, ASCIIString}()
  for (k, f) in zip(ks, df_files)
    name2file_map[k] = f
  end
  return name2file_map
end

const NAME2FILE_MAP = get_name2file_map()
const ASCII_CR = Pkg.dir("RLESCAS/src/clustering/data/dasc_clusters/ascii_clusters.json")

function one_vs_all_labelmap(labels::Vector{Int64}, poslabel::Int64)
  label_map = Dict{Int64, Bool}()
  for i in unique(labels)
    label_map[i] = false
  end
  label_map[poslabel] = true
  return label_map
end

function one_vs_one_labelmap(labels::Vector{Int64}, poslabel::Int64, neglabel::Int64)
  return label_map = Dict{Int64, Bool}([poslabel => true, neglabel => false])
end

function script6() #try to separate real clusters
  Dsl = load_from_clusterresult(ASCII_CR, NAME2FILE_MAP)
  label_map = one_vs_one_labelmap(Dsl.labels, 0, 2)
  Dsl = maplabels(Dsl, label_map)
  #not sure what to expect
  (f, ind, pred, code) = learn_rule(Dsl)
end

function script9() #real clusters 1 vs others
  Dsl = load_from_clusterresult(ASCII_CR, NAME2FILE_MAP)
  label_map = one_vs_all_labelmap(Dsl.labels, 3)
  Dsl = maplabels(Dsl, label_map)
  #not sure what to expect
  (f, ind, pred, code) = learn_rule(Dsl)
end

function script11() #1 on 1
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 5:6)
  labels = [false, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end

function script12() #1 on others
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 1:5)
  labels = [false, true, true, true, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end

function script13() #2 on others
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 1:4)
  labels = [false, false, true, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end

function script14() #random clustering
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 1:6)
  labels = [false, true, false, true, false, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end

function script15() #random clustering
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 1:10)
  labels = [false, false, true, true, false, false, true, true, false, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end

#TODOs:
#try to explain Mykel's clusterings?
#refactor tests
#visualization, d3?
#papers
#survey

