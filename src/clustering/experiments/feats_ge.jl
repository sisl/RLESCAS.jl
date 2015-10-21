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

push!(LOAD_PATH, "./")
push!(LOAD_PATH, "../") #clustering folder

using RLESUtils.FileUtils
using RLESUtils.StringUtils
using RLESUtils.MathUtils
using RLESUtils.LookupCallbacks
using CSVFeatures
using ClusterResults
using Iterators
using DataFrames
using GrammaticalEvolution

typealias RealVec Union(DataArray{Float64,1}, Vector{Float64})

const FEATURE_MAP = LookupCallback[
  LookupCallback("ra_detailed.ra_active", bool),
  LookupCallback("ra_detailed.ownInput.dz"),
  LookupCallback(["ra_detailed.ownInput.z", "ra_detailed.intruderInput[1].z"], (z1, z2) -> z2 - z1),
  LookupCallback("ra_detailed.ownInput.psi"),
  LookupCallback("ra_detailed.intruderInput[1].sr"),
  LookupCallback("ra_detailed.intruderInput[1].chi"),
  LookupCallback("ra_detailed.intruderInput[1].cvc"), #categorical size?
  LookupCallback("ra_detailed.intruderInput[1].vrc"), #categorical size?
  LookupCallback("ra_detailed.intruderInput[1].vsb"), #categorical size?
  LookupCallback("ra_detailed.ownOutput.cc", x -> bin(int(x), 3)[1] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.cc", x -> bin(int(x), 3)[2] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.cc", x -> bin(int(x), 3)[3] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.vc", x -> bin(int(x), 3)[1] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.vc", x -> bin(int(x), 3)[2] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.vc", x -> bin(int(x), 3)[3] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.ua", x -> bin(int(x), 3)[1] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.ua", x -> bin(int(x), 3)[2] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.ua", x -> bin(int(x), 3)[3] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.da", x -> bin(int(x), 3)[1] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.da", x -> bin(int(x), 3)[2] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.da", x -> bin(int(x), 3)[3] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.target_rate"),
  LookupCallback("ra_detailed.ownOutput.crossing", bool),
  LookupCallback("ra_detailed.ownOutput.alarm", bool),
  LookupCallback("ra_detailed.ownOutput.alert", bool),
  LookupCallback("ra_detailed.intruderOutput[1].cvc"), #categorical size?
  LookupCallback("ra_detailed.intruderOutput[1].vrc"), #categorical size?
  LookupCallback("ra_detailed.intruderOutput[1].vsb"), #categorical size?
  LookupCallback("ra_detailed.intruderOutput[1].tds"),
  LookupCallback("response.state", x -> x == "none"), #split categorical to 1-hot
  LookupCallback("response.state", x -> x == "stay"), #split categorical to 1-hot
  LookupCallback("response.state", x -> x == "follow"), #split categorical to 1-hot
  LookupCallback("response.timer"),
  LookupCallback("response.h_d"),
  LookupCallback("response.psi_d")
  ]

const FEATURE_NAMES = ASCIIString[
  "RA",
  "vert_rate",
  "alt_diff",
  "psi",
  "intr_sr",
  "intr_chi",
  "intr_cvc",
  "intr_vrc",
  "intr_vsb",
  "cc1",
  "cc2",
  "cc3",
  "vc1",
  "vc2",
  "vc3",
  "ua1",
  "ua2",
  "ua3",
  "da1",
  "da2",
  "da3",
  "target_rate",
  "crossing",
  "alarm",
  "alert",
  "intr_out_cvc",
  "intr_out_vrc",
  "intr_out_vsb",
  "intr_out_tds",
  "response_none",
  "response_stay",
  "response_follow",
  "response_timer",
  "response_h_d",
  "response_psi_d"
  ]

append(V::Vector{ASCIIString}, s::String) = map(x -> "$(x)$(s)", V)

get_col_types(D::DataFrame) = [typeof(D.columns[i]).parameters[1] for i=1:length(D.columns)]

include("ge/RNGWrapper.jl")
using RNGWrapper

include("ge/ExamplePopulation.jl")

convert_number(lst) = float(join(lst))

function create_grammar()
  @grammar grammar begin
    start = bin

    bin = and | or | not | always | eventually #implies, until, next, release and weak until not implemented
    and = Expr(:&&, bin, bin)
    or = Expr(:||, bin, bin)
    not = Expr(:call, :!, bin)
    always = Expr(:call, :all, bin_vec) #global
    eventually = Expr(:call, :any, bin_vec) #future

    bin_vec = vec_and | vec_or | vec_not | vec_lte | vec_diff_lte | vec_absdiff_lte
    vec_and = Expr(:call, :&, bin_vec, bin_vec)
    vec_or = Expr(:call, :|, bin_vec, bin_vec)
    vec_not = Expr(:call, :!, bin_vec)
    vec_lte = Expr(:comparison, real_feat_vec, :.<=, real_number) | Expr(:comparison, real_feat_vec, :.<=, real_feat_vec) | Expr(:comparison, real_number, :.<=, real_feat_vec)
    vec_diff_lte = Expr(:call, :diff_lte, real_feat_vec, real_feat_vec, real_number)
    vec_absdiff_lte = Expr(:call, :abs_diff_lte, real_feat_vec, real_feat_vec, real_number)

    real_feat_vec = Expr(:ref, :D, :(:), real_feat_id)
    bin_feat_vec = Expr(:ref, :D, :(:), bin_feat_id)
    real_feat_id = 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 22 | 26 | 27 | 28 | 29 | 33 | 34 | 35 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 57 | 61 | 62 | 63 | 64 | 68 | 69 | 70
    bin_feat_id = 1 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 23 | 24 | 25 | 30 | 31 | 32 | 36 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 58 | 59 | 60 | 65 | 66 | 67

    #real_number = Expr(:call, :get_rand, real_feat_id)
    real_number[convert_number] = digit + '.' + digit
    digit = 0:9
  end

  return grammar
end

diff_lte(v1::RealVec, v2::RealVec, b::Float64) = (v1 - v2) .<= b
abs_diff_lte(v1::RealVec, v2::RealVec, b::Float64) = abs(v1 - v2) .<= b
get_rand(id::Int64) = rand() #for now...

function grammar_test(pop_size::Int64, genome_size::Int64, maxwraps::Int64)
  #rsg = RSG(2, 2)
  #set_global(rsg)

  # our grammar
  grammar = create_grammar()

  # create population
  pop = ExamplePopulation(pop_size, genome_size)

  ngood = 0
  nbad = 0
  ntotal = 0

  for ind in pop.individuals
    try
      ind.code = transform(grammar, ind, maxwraps=maxwraps)
      @show ind.code
      ngood += 1
      ntotal += 1
    catch e
      println("exception = $e")
      nbad += 1
      ntotal += 1
    end
  end

  @show ngood
  @show nbad
  @show ntotal
  return pop
end

const DF_DIR = "./ge"
const GRAMMAR = create_grammar()
const W1 = 0.001
const GENOME_SIZE = 200
const POP_ZIE = 5000

function GrammaticalEvolution.evaluate!(grammar::Grammar, ind::ExampleIndividual, Ds::Vector{DataFrame}, labels::Vector{Bool})
  try
    ind.code = transform(grammar, ind, maxwraps=maxwraps)
    @eval fn(D) = $(ind.code)
  catch e
    #println("exception = $e")
    #@show ind.code
    ind.fitness = Inf
    return
  end

  @assert length(Ds) == length(labels)
  predicted_labels = map(fn, Ds_pos)
  accuracy = count(identity, predicted_labels .== labels) / length(labels)
  if 0.0 < accuracy < 0.5
    ind.code = negate_expr(ind.code)
    accuracy = 1.0 - accuracy
  end

  ind.fitness = accuracy + W1*length(string(ind.code))
end

function negate_expr(ex::Expr)
  return parse("!($ex)")
end

function learn_rule(Ds::Vector{DataFrame}, labels::Vector{Bool}, n_iterations::Int64,
                    grammar::Grammar=GRAMMAR, pop_size::Int64=POP_SIZE,
                    genome_size::Int64=GENOME_SIZE, maxwraps::Int64=MAXWRAPS)
  #rsg = RSG(2, 2)
  #set_global(rsg)

  # create population
  pop = ExamplePopulation(pop_size, genome_size)

  generation = 1
  while generation < n_iterations
    # generate a new population (based off of fitness)
    pop = generate(grammar, pop, 0.1, 0.2, 0.2, Ds, labels)

    # population is sorted, so first entry it the best
    fitness = pop[1].fitness
    println("generation: $generation, max fitness=$fitness, code=$(pop[1].code)")
    generation += 1
  end
  return pop[1] #return best
end

convert2dataframes() = csv_to_dataframe("../data/dasc_nmacs", outdir=DF_DIR)

function main()
  files = readdir_ext("csv", DF_DIR) |> sort! #csvs
  all_DFs = map(readtable, files)
  cr = load_results("./ge/cluster_results.jl")
  ids0 = find(x -> x == 0, cr.labels)
  ids1 = find(x -> x == 2, cr.labels)


end
