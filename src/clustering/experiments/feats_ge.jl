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
using DataFrameFeatures
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
  LookupCallback("ra_detailed.intruderInput[1].vrc", x -> x == 0), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderInput[1].vrc", x -> x == 1), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderInput[1].vrc", x -> x == 2), #split categorical to 1-hot
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
  LookupCallback("ra_detailed.intruderOutput[1].vrc", x -> x == 0), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderOutput[1].vrc", x -> x == 1), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderOutput[1].vrc", x -> x == 2), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderOutput[1].tds"),
  LookupCallback("response.state", x -> x == "none"), #split categorical to 1-hot
  LookupCallback("response.state", x -> x == "stay"), #split categorical to 1-hot
  LookupCallback("response.state", x -> x == "follow"), #split categorical to 1-hot
  LookupCallback("response.timer"),
  LookupCallback("response.h_d"),
  LookupCallback("response.psi_d"),
  LookupCallback("adm.v"),
  LookupCallback("adm.h")
  ]

const FEATURE_NAMES = ASCIIString[
  "RA",
  "vert_rate",
  "alt_diff",
  "psi",
  "intr_sr",
  "intr_chi",
  "intr_vrc0",
  "intr_vrc1",
  "intr_vrc2",
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
  "intr_out_vrc0",
  "intr_out_vrc1",
  "intr_out_vrc2",
  "intr_out_tds",
  "response_none",
  "response_stay",
  "response_follow",
  "response_timer",
  "response_h_d",
  "response_psi_d",
  "v",
  "h"
  ]

function is_converging(psi1::Float64, chi1::Float64, psi2::Float64, chi2::Float64)
  #println("psi1=$psi1, chi1=$chi1, psi2=$psi2, chi2=$chi2")
  if abs(chi1) > pi/2 && abs(chi2) > pi/2 #flying away from each other
    return false
  end
  z1 = to_plusminus_pi(psi2 - psi1)
  z2 = to_plusminus_pi(psi1 - psi2)
  return z1 * chi1 <= 0 && z2 * chi2 <= 0
end

const ADD_FEATURE_MAP = LookupCallback[
  LookupCallback(["psi_1", "intr_chi_1", "psi_2", "intr_chi_2"], is_converging)
  ]

const ADD_FEATURE_NAMES = ASCIIString[
  "converging"
  ]

get_col_types(D::DataFrame) = [typeof(D.columns[i]).parameters[1] for i=1:length(D.columns)]
function make_type_string(D::DataFrame)
  Ts = get_col_types(D)
  Ts = map(string, Ts)
  @assert all(x->x=="Bool" || x=="Float64", Ts)
  io = IOBuffer()
  for id in find(x->x=="Bool", Ts)
    print(io, id, " | ")
  end
  bin_string = takebuf_string(io)[1:end-3]
  println("bin_feat_id = ", bin_string)
  io = IOBuffer()
  for id in find(x->x=="Float64", Ts)
    print(io, id, " | ")
  end
  real_string = takebuf_string(io)[1:end-3]
  println("real_feat_id = ", real_string)
  return bin_string, real_string
end

include("ge/RNGWrapper.jl")
using RNGWrapper

include("ge/ExamplePopulation.jl")

convert_number(lst) = float(join(lst))

function create_grammar()
  @grammar grammar begin
    start = bin

    #produces bin
    bin = and | or | not | implies | always | eventually | until | weakuntil | release | next | lte | lt #goto?
    and = Expr(:&&, bin, bin)
    or = Expr(:||, bin, bin)
    not = Expr(:call, :!, bin)
    implies = Expr(:call, :Y, bin_vec, bin_vec) | Expr(:call, :Y, bin, bin)
    always = Expr(:call, :G, bin_vec) #global
    eventually = Expr(:call, :F, bin_vec) #future
    until = Expr(:call, :U, bin_vec, bin_vec) #until
    weakuntil = Expr(:call, :W, bin_vec, bin_vec) #weak until
    release = Expr(:call, :R, bin_vec, bin_vec) #release
    next = Expr(:call, :X, bin_vec) #next
    lte = Expr(:comparison, real, :<=, real_number) | Expr(:comparison, real, :<=, real) | Expr(:comparison, real_number, :<=, real)
    lt = Expr(:comparison, real, :<, real_number) | Expr(:comparison, real, :<, real) | Expr(:comparison, real_number, :<, real)

    #produces a bin_vec
    bin_vec = bin_feat_vec | vec_and | vec_or | vec_not | vec_lte | vec_diff_lte | vec_lt | vec_diff_lt | sign
    vec_and = Expr(:call, :&, bin_vec, bin_vec)
    vec_or = Expr(:call, :|, bin_vec, bin_vec)
    vec_not = Expr(:call, :!, bin_vec)
    vec_lte = Expr(:comparison, real_feat_vec, :.<=, real_number) | Expr(:comparison, real_feat_vec, :.<=, real_feat_vec) | Expr(:comparison, real_number, :.<=, real_feat_vec)
    vec_lt = Expr(:comparison, real_feat_vec, :.<, real_number) | Expr(:comparison, real_feat_vec, :.<, real_feat_vec) | Expr(:comparison, real_number, :.<, real_feat_vec)
    vec_diff_lte = Expr(:call, :de, real_feat_vec, real_feat_vec, real_number)
    vec_diff_lt = Expr(:call, :dl, real_feat_vec, real_feat_vec, real_number)
    sign = Expr(:call, :sn, real_feat_vec, real_feat_vec)

    #produces a real
    real = count
    count = Expr(:call, :ct, bin_vec)

    #based on features
    real_feat_vec = Expr(:ref, :D, :(:), real_feat_id)
    bin_feat_vec = Expr(:ref, :D, :(:), bin_feat_id)
    real_feat_id = real_feat_id = 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 22 | 26 | 27 | 28 | 29 | 33 | 34 | 35 | 36 | 37 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 59 | 63 | 64 | 65 | 66 | 70 | 71 | 72 | 73 | 74
    bin_feat_id = 1 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 23 | 24 | 25 | 30 | 31 | 32 | 38 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 60 | 61 | 62 | 67 | 68 | 69 | 75

    #random numbers
    real_number = Expr(:call, :rn, expdigit, rand_pos) | Expr(:call, :rn, expdigit, rand_neg)
    expdigit = -4:4
    rand_pos[convert_number] =  digit + '.' + digit + digit + digit + digit
    rand_neg[convert_number] =  '-' + digit + '.' + digit + digit + digit + digit
    digit = 0:9
  end

  return grammar
end

get_real(n::Int64, x::Float64) = x * 10.0^n #compose_real
get_real(n::Int64, c::Char) = rn(n, string(c)) #for debug only
function get_real(n::Int64, s::String) #for debug only
  println("n=$n, s=$s")
  throw(DomainError())
end
diff_lte(v1::RealVec, v2::RealVec, b::Float64) = (v1 - v2) .<= b
diff_lt(v1::RealVec, v2::RealVec, b::Float64) = (v1 - v2) .< b

function until(v1::AbstractVector{Bool}, v2::AbstractVector{Bool})
  t = findfirst(v2)
  if t > 0
    return all(v1[1:t-1])
  else #true not found
    return false
  end
end

function weak_until(v1::AbstractVector{Bool}, v2::AbstractVector{Bool})
  t = findfirst(v2)
  if t > 0
    return all(v1[1:t - 1])
  else #true not found
    return all(v1)
  end
end

function release(v1::AbstractVector{Bool}, v2::AbstractVector{Bool})
  t = findfirst(v2)
  if t > 0
    return all(v1[1:t])
  else #true not found
    return all(v1)
  end
end

next_(v::AbstractVector{Bool}) = v[2]
implies(b1::Bool, b2::Bool) = !b1 || b2
function implies(v1::AbstractVector{Bool}, v2::AbstractVector{Bool})
  ids = find(v1)
  return v2[ids] |> all
end

sign_(v1::RealVec, v2::RealVec) = (sign(v1) .* sign(v2)) .>= 0.0 #same sign, 0 matches any sign
count_f(v::AbstractVector{Bool}) = count(identity, v) |> float

#shorthands used in grammar
rn = get_real
de = diff_lte
dl = diff_lt
F = any
G = all
U = until
W = weak_until
R = release
X = next_ #avoid conflict with Base.next
Y = implies
sn = sign_ #avoid conflict with Base.sign
ct = count_f

function grammar_test(pop_size::Int64=POP_SIZE, genome_size::Int64=GENOME_SIZE, maxwraps::Int64=MAXWRAPS)
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
      ind.code = nothing
      nbad += 1
      ntotal += 1
    end
  end

  @show ngood
  @show nbad
  @show ntotal
  return filter(ind -> ind.code != nothing, pop)
end

const DF_DIR = "./ge"
const GRAMMAR = create_grammar()
const W1 = 0.0001 #code length
const W2 = 0#.001 #noise
const GENOME_SIZE = 500
const POP_SIZE = 10000
const MAXWRAPS = 2
const N_ITERATIONS = 5

function GrammaticalEvolution.evaluate!(grammar::Grammar, ind::ExampleIndividual, Ds::Vector{DataFrame}, labels::AbstractVector{Bool})
  predicted_labels = nothing
  try
    ind.code = transform(grammar, ind, maxwraps=MAXWRAPS)
    @eval fn(D) = $(ind.code)
    predicted_labels = map(fn, Ds)
  catch e
    if !isa(e, MaxWrapException)
      println("exception = $e")
      println("code: $(ind.code)")
    end
    ind.code = :(throw($e))
    ind.fitness = Inf
    return
  end
  @assert length(Ds) == length(labels)
  accuracy = count(identity, predicted_labels .== labels) / length(labels)
  if 0.0 <= accuracy < 0.5
    ind.code = negate_expr(ind.code)
    accuracy = 1.0 - accuracy
  end
  err = 1.0 - accuracy
  #ind.fitness = err + W1*length(string(ind.code)) + W2*rand()
  ind.fitness = err > 0.0 ? err : W1*length(string(ind.code))
end

negate_expr(ex::Expr) = parse("!($ex)")

function learn_rule(Ds::Vector{DataFrame}, labels::AbstractVector{Bool}, n_iterations::Int64,
                    grammar::Grammar=GRAMMAR, pop_size::Int64=POP_SIZE,
                    genome_size::Int64=GENOME_SIZE, maxwraps::Int64=MAXWRAPS)
  println("learn_rule()")
  #rsg = RSG(2, 2)
  #set_global(rsg)

  # create population
  pop = ExamplePopulation(pop_size, genome_size)

  generation = 1
  while generation <= n_iterations
    # generate a new population (based off of fitness)
    pop = generate(grammar, pop, 0.1, 0.2, 0.2, Ds, labels)

    # population is sorted, so first entry it the best
    fitness = pop[1].fitness
    println("generation: $generation, max fitness=$fitness, code=$(pop[1].code)")
    generation += 1
  end
  return pop[1] #return best
end

function convert2dataframes()
  csvfiles = readdir_ext("csv", "../data/dasc_nmacs")
  df_files = csv_to_dataframe(csvfiles, FEATURE_MAP, FEATURE_NAMES, outdir=DF_DIR)
  add_features!(df_files, ADD_FEATURE_MAP, ADD_FEATURE_NAMES, overwrite=true)
end

function fileroot_to_dataframe{T<:String}(fileroots::Vector{T}; dir::String="")
  map(fileroots) do f
    fileroot_to_dataframe(f, dir=dir)
  end
end
#TODO: clean this up, make less assumptions on cr.names
function fileroot_to_dataframe(fileroot::String; dir::String="./")
  return joinpath(dir, "$(fileroot)_dataframe.csv")
end

function cluster_test(Ds::Vector{DataFrame}, labels::AbstractVector{Bool})
  ind = learn_rule(Ds, labels, N_ITERATIONS)
  @eval f(D) = $(ind.code)
  pred = map(f, Ds)
  return (f, ind, pred)
end

function get_Ds()
  files = readdir_ext("csv", DF_DIR) |> sort! #csvs
  Ds = map(readtable, files)
  return files, Ds
end

function get_Ds(cluster_neg::Int64, cluster_pos::Int64)
  cr = load_result("./ge/cluster_results.json")
  ids0 = find(x -> x == cluster_neg, cr.labels)
  ids1 = find(x -> x == cluster_pos, cr.labels)
  Ds0 = map(readtable, fileroot_to_dataframe(cr.names[ids0], dir=DF_DIR))
  Ds1 = map(readtable, fileroot_to_dataframe(cr.names[ids0], dir=DF_DIR))
  Ds = vcat(Ds0, Ds1)
  labels = vcat(falses(length(Ds0)), trues(length(Ds1)))
  return (Ds, labels)
end

function direct_sample(Ds::Vector{DataFrame}, labels::AbstractVector{Bool}, genome_size::Int64, nsamples::Int64)

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

function fill_to_col!{T}(Ds::Vector{DataFrame}, field_id::Int64, fillvals::AbstractVector{T})
  @assert length(Ds) == length(fillvals)
  for i = 1:length(Ds)
    fill!(Ds[i].columns[field_id], fillvals[i])
  end
end

function script1()
  Ds, labels = get_Ds(0,2)
  fill_to_col!(Ds, 1, !labels)
  #should give: all(!D[:,1])
  (f, ind, pred) = cluster_test(Ds, labels)
end

function script2()
  Ds, labels = get_Ds(0,2)
  fill_to_col!(Ds, 2, map(x -> x ? 25.0 : -5.0, labels))
  #should give: all(0.0 .<= D[:,2])
  (f, ind, pred) = cluster_test(Ds, labels)
end

function script3()
  #should give ngood close to 1000
  grammar_test(1000, 500, 2)
end

function samedir_firstRA!(Ds::Vector{DataFrame}, labels::AbstractVector{Bool})
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
  Ds, labels = get_Ds(1,4)
  samedir_firstRA!(Ds, labels)
  #should give: Y(D[:,alarm1] && D[:,resp_none1], sn(D[:,:target_rate1], D[:,:vert_rate1]))
  #should give: Y(D[:,24] && D[:,30], sn(D[:,22], D[:,2]))
  (f, ind, pred) = cluster_test(Ds, labels)
end

function script5()
  Ds, labels = get_Ds(0,2)
  samedir_firstRA!(Ds, labels)
  direct_sample(Ds, labels, 500, 100000)
end

function script6() #try to separate real clusters
  Ds, labels = get_Ds(1,4)
  #not sure what to expect
  (f, ind, pred) = cluster_test(Ds, labels)
end

#TODOs:
#try to explain Mykel's clusterings?
#inject other properties as tests
#papers
#survey

