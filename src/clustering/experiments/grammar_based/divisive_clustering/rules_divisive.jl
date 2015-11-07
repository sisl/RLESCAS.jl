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

import Base.convert
using DivisiveTrees
using TikzQTrees
using DataFrameSets
using Iterators
using DataFrames

const DF_DIR = Pkg.dir("RLESCAS/src/clustering/data/dasc_nmacs_ts_feats")

const GRAMMAR = create_grammar()
const W1 = 0.001 #code length
const GENOME_SIZE = 500
const POP_SIZE = 10000
const MAXWRAPS = 2
const N_ITERATIONS = 5

function find_rule(Ds::Vector{DataFrame}, nsamples::Int64)
  best_ind = ExampleIndividual(GENOME_SIZE, 1000) #maxvalue=1000
  best_ind.fitness = Inf
  labels = "empty"
  for i = 1:nsamples
    ind = ExampleIndividual(GENOME_SIZE, 1000)
    try
      ind.code = transform(GRAMMAR, ind, maxwraps=MAXWRAPS)
      @eval fn(D) = $(ind.code)
      labels = map(fn, Ds)
      ind.fitness = cost = (1.0 - entropy(labels)) + W1*length(string(ind.code))
    catch e
      if !isa(e, MaxWrapException)
        println("exception = $e")
        println("code: $(ind.code)")
      end
      ind.code = :(throw($e))
      ind.fitness = Inf
      return
    end
    s = string(ind.code)
    l = min(length(s), 50)
    #println("$i: fitness=$(ind.fitness), best=$(best_ind.fitness), length=$(length(s)), code=$(s[1:l])")
    if 0.0 < ind.fitness < best_ind.fitness
      best_ind = ind
    end
  end
  s = string(best_ind.code)
  l = min(length(s), 50)
  println("best: fitness=$(best_ind.fitness), length=$(length(s)), code=$(s[1:l])")
  return best_ind
end

function get_rule(S::DTSet, records::Vector{Int64})
  ind = find_rule(S.records[records], 1000)
  return ind
end

function predict(split_rule::ExampleIndividual, S::DTSet, records::Vector{Int64})
  ind = split_rule
  @eval f(D) = $(ind.code)
  return pred = map(f, S.records[records])
end

function stopcriterion{T}(split_result::Vector{T}, depth::Int64, nclusters::Int64)
  depth >= 3
end

function entropy{T}(labels::Vector{T})
  out = 0.0
  for l in unique(labels)
    p = count(x -> x == l, labels) / length(labels)
    if p != 0.0
      out += - p * log(2, p)
    end
  end
  return out
end

function get_node_text(node::DTNode, colnames::Vector{ASCIIString})
  if node.split_rule != nothing
    s = "id=$(node.members)\\\\$(node.split_rule.code)"
    s = sub_varnames(s, colnames)
    s = replace(s, "_", "\\_") #TODO: move these to a util package, use LatexString?
    s = replace(s, "|", "\$|\$")
    s = replace(s, "<", "\$<\$")
    s = replace(s, ">", "\$>\$")
    return s
  else
    return "id=$(node.members)"
  end
end

get_arrow_text(val) = string(val)

function sub_varnames{T<:String}(s::String, colnames::Vector{T})
  r = r"D\[:,([0-9]+)\]"
  for m in eachmatch(r, s)
    id = m.captures[1] |> int
    s = replace(s, m.match, colnames[id])
  end
  return s
end

convert(::Type{DTSet}, Ds::DFSet) = DTSet(Ds.records)

function script1()
  Ds, files = load_from_dir(DF_DIR)
  S = convert(DTSet, Ds)
  p = DTParams(get_rule, predict, stopcriterion)
  dtree = build_tree(S, p)
  colnames = get_colnames(Ds)
  stree = convert_tree(dtree, x -> get_node_text(x, colnames), get_arrow_text)
  plottree(stree, output="TEXPDF")
  return (dtree, stree)
end
