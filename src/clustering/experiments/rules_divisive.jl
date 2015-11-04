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

push!(LOAD_PATH, Pkg.dir("RLESCAS/src/clustering"))
push!(LOAD_PATH, Pkg.dir("RLESCAS/src/clustering/experiments"))
push!(LOAD_PATH, Pkg.dir("RLESCAS/src/clustering/experiments/divisivetrees"))

include("divisivetrees/visualize.jl")

using DivisiveTrees
using SimpleTrees
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
    bin =  implies | always | eventually | until | weakuntil | release | lte | lt #and | or | not | next#goto?
    #and = Expr(:&&, bin, bin)
    #or = Expr(:||, bin, bin)
    #not = Expr(:call, :!, bin)
    implies = Expr(:call, :Y, bin_vec, bin_vec) | Expr(:call, :Y, bin, bin) | Expr(:call, :Yl, bin_vec, bin_vec) | Expr(:call, :Yy, bin_vec, bin_vec) | Expr(:call, :Yx, bin_vec, bin_vec)
    always = Expr(:call, :G, bin_vec) #global
    eventually = Expr(:call, :F, bin_vec) #future
    until = Expr(:call, :U, bin_vec, bin_vec) #until
    weakuntil = Expr(:call, :W, bin_vec, bin_vec) #weak until
    release = Expr(:call, :R, bin_vec, bin_vec) #release
    #next = Expr(:call, :X, bin_vec) #next
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
    real_feat_id = 2 | 3 | 4 | 5 | 6 | 22 | 29 | 33 | 34 | 35 | 36 | 37 | 39 | 40 | 41 | 42 | 43 | 59 | 66 | 70 | 71 | 72 | 73 | 74
    bin_feat_id = 1 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 23 | 24 | 25 | 26 | 27 | 28 | 30 | 31 | 32 | 38 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 60 | 61 | 62 | 63 | 64 | 65 | 67 | 68 | 69 | 75

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

next_(v::AbstractVector{Bool}) = length(v) >= 2 ? v[2] : false
implies(b1::Bool, b2::Bool) = !b1 || b2
function implies(v1::AbstractVector{Bool}, v2::AbstractVector{Bool}) #true at same time step
  ids = find(v1)
  return v2[ids] |> all
end
function implies(v1::AbstractVector{Bool}, v2::AbstractVector{Bool}, op::Function) #operator true at subsequent steps
  ts = find(v1)
  for t in ts
    if !op(v2[t:end])
      return false
    end
  end
  return true
end
implies_all(v1::AbstractVector{Bool}, v2::AbstractVector{Bool}) = implies(v1, v2, all)
implies_any(v1::AbstractVector{Bool}, v2::AbstractVector{Bool}) = implies(v1, v2, any)
implies_next(v1::AbstractVector{Bool}, v2::AbstractVector{Bool}) = implies(v1, v2, next_)

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
Yl = implies_all
Yy = implies_any
Yx = implies_next
sn = sign_ #avoid conflict with Base.sign
ct = count_f

const DF_DIR = "./ge"
const GRAMMAR = create_grammar()
const W1 = 0.001 #code length
const GENOME_SIZE = 500
const POP_SIZE = 10000
const MAXWRAPS = 2
const N_ITERATIONS = 5

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

function get_Ds()
  files = readdir_ext("csv", DF_DIR) |> sort! #csvs
  Ds = map(readtable, files)
  return files, Ds
end

function find_rule(Ds::Vector{DataFrame}, nsamples::Int64)
  best_ind = ExampleIndividual(GENOME_SIZE, 1000)
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

function script1()
  files, Ds = get_Ds()
  S = DataSet(Ds)
  p = DTParams(get_rule, predict, stopcriterion)
  dtree = build_tree(S, p)
  stree = DT2ST(dtree, get_node_text, get_arrow_text)
  plottree(stree, output="TEXPDF")
  return (dtree, stree)
end

function get_rule(S::DataSet, records::Vector{Int64})
  ind = find_rule(S.records[records], 1000)
  return ind
end

function predict(split_rule::ExampleIndividual, S::DataSet, records::Vector{Int64})
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

function get_colnames()
  files, Ds = get_Ds()
  return map(string, names(Ds[1]))
end

const COLNAMES = get_colnames()

function get_node_text(node::DTNode)
  if node.split_rule != nothing
    s = "id=$(node.members)\\\\$(node.split_rule.code)"
    r = r"D\[:,([0-9]+)\]"
    for m in eachmatch(r, s)
      id = m.captures[1] |> int
      colname = COLNAMES[id]
      s = replace(s, m.match, colname)
    end
    s = replace(s, "_", "\\_") #TODO: move these to a util package
    s = replace(s, "|", "\$|\$")
    s = replace(s, "<", "\$<\$")
    s = replace(s, ">", "\$>\$")
    return s
  else
    return "id=$(node.members)"
  end
end

get_arrow_text(val) = string(val)

