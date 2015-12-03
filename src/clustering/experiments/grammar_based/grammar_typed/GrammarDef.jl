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

module GrammarDef

export create_grammar, feat_type_ids, to_function, pretty_string

using RLESUtils.DataFramesUtils
using GrammaticalEvolution
using DataFrames

typealias RealVec Union{DataArray{Float64,1}, Vector{Float64}}

function create_grammar(D::DataFrame)
  @grammar grammar begin
    start = bin

    bin = always | eventually | top_and | top_or | top_not
    top_and = Expr(:&&, bin, bin)
    top_or = Expr(:||, bin, bin)
    top_not = Expr(:call, :!, bin)
    always = Expr(:call, :G, bin_vec) #global
    eventually = Expr(:call, :F, bin_vec) #future

    #produces a bin_vec
    bin_vec = bin_feat_vec | and | or | not | implies | eq | lt | lte | diff_eq | diff_lt | diff_lte |
      sign | count
    and = Expr(:call, :&, bin_vec, bin_vec)
    or = Expr(:call, :|, bin_vec, bin_vec)
    not = Expr(:call, :!, bin_vec)
    implies = Expr(:call, :Y, bin_vec, bin_vec)
    eq = Expr(:comparison, real_feat_vec, :.==, real_number) | Expr(:comparison, real_feat_vec, :.==, real_feat_vec)
    lt = Expr(:comparison, real_feat_vec, :.<, real_number) | Expr(:comparison, real_feat_vec, :.<, real_feat_vec) |
          Expr(:comparison, real_number, :.<, real_feat_vec)
    lte = Expr(:comparison, real_feat_vec, :.<=, real_number) | Expr(:comparison, real_feat_vec, :.<=, real_feat_vec) |
          Expr(:comparison, real_number, :.<=, real_feat_vec)
    diff_eq = Expr(:call, :dfeq, real_feat_vec, real_feat_vec, real_number)
    diff_lt = Expr(:call, :dflt, real_feat_vec, real_feat_vec, real_number)
    diff_lte = Expr(:call, :dfle, real_feat_vec, real_feat_vec, real_number)
    sign = Expr(:call, :sn, real_feat_vec, real_feat_vec)
    count = Expr(:call, :ctlt, bin_vec, real_number) | Expr(:call, :ctle, bin_vec, real_number) | Expr(:call, :ctgt, bin_vec, real_number) | Expr(:call, :ctge, bin_vec, real_number) | Expr(:call, :cteq, bin_vec, real_number)

    #based on features
    real_feat_vec = Expr(:ref, :D, :(:), real_feat_id)
    bin_feat_vec = Expr(:ref, :D, :(:), bin_feat_id)

    #random numbers
    real_number = rand_pos | rand_neg
    rand_pos =  Expr(:call, :rp, expdigit, digit, digit, digit, digit, digit)
    rand_neg =  Expr(:call, :rn, expdigit, digit, digit, digit, digit, digit)
    digit = 0:9
    expdigit = -8:0
  end

  #automatically determine real vs bool columns from DataFrame
  (bin_ids, real_ids) = feat_type_ids(D)
  bin_terms = map(GrammaticalEvolution.Terminal, bin_ids)
  grammar.rules[:bin_feat_id] = OrRule("bin_feat_id", bin_terms, nothing)
  real_terms = map(GrammaticalEvolution.Terminal, real_ids)
  grammar.rules[:real_feat_id] = OrRule("real_feat_id", real_terms, nothing)

  return grammar
end

get_real_pos(n::Int64, ds::Int64...) = float(join(ds)) * 10.0^n #compose_real
get_real_neg(n::Int64, ds::Int64...) = -float(join(ds)) * 10.0^n #compose_real
diff_eq(v1::RealVec, v2::RealVec, b::Float64) = (v1 - v2) .== b
diff_lte(v1::RealVec, v2::RealVec, b::Float64) = (v1 - v2) .<= b
diff_lt(v1::RealVec, v2::RealVec, b::Float64) = (v1 - v2) .< b

eventually(v::AbstractVector{Bool}) = any(v)
globally(v::AbstractVector{Bool}) = all(v)
implies(v1::AbstractVector{Bool}, v2::AbstractVector{Bool}) = !v1 | v2

sign_(v1::RealVec, v2::RealVec) = (sign(v1) .* sign(v2)) .>= 0.0 #same sign, 0 matches any sign
count_(v::AbstractVector{Bool}) = Float64[count(identity, v[t:end]) for t = 1:endof(v)]
count_eq(v::AbstractVector{Bool}, b::Float64) = count_(v) .== b
count_lt(v::AbstractVector{Bool}, b::Float64) = count_(v) .< b
count_lte(v::AbstractVector{Bool}, b::Float64) = count_(v) .<= b
count_gt(v::AbstractVector{Bool}, b::Float64) = count_(v) .> b
count_gte(v::AbstractVector{Bool}, b::Float64) = count_(v) .>= b

#shorthands used in grammar
rp = get_real_pos
rn = get_real_neg
dfeq = diff_eq
dfle = diff_lte
dflt = diff_lt
F = eventually
G = globally
Y = implies
sn = sign_ #avoid conflict with Base.sign
ctlt = count_lt
ctle = count_lte
ctgt = count_gt
ctge = count_gte
cteq = count_eq

function feat_type_ids(D::DataFrame; verbose::Bool=false)
  Ts = map(string, get_col_types(D))
  @assert all(x->x=="Bool" || x=="Float64", Ts)
  bin_ids = find(x -> x == "Bool", Ts)
  real_ids = find(x -> x == "Float64", Ts)
  if verbose
    println("bin_feat_id = $(join(bin_ids, " | "))")
    println("real_feat_id = $(join(real_ids, " | "))")
  end
  return (bin_ids, real_ids)
end

function to_function(code::Expr)
  @eval f(D) = $code
  return f
end

function pretty_string{T<:AbstractString}(code::AbstractString, colnames::Vector{T})
  s = code
  #remove spaces
  s = replace(s, " ", "")
  #sub variables
  s = sub_varnames(s, colnames)
  #replace floats
  s = sub_reals(s)
  return s
end

function sub_varnames{T<:AbstractString}(s::AbstractString, colnames::Vector{T})
  r = r"D\[:,(\d+)\]"
  for m in eachmatch(r, s)
    id = parse(Int, m.captures[1])
    s = replace(s, m.match, colnames[id])
  end
  return s
end

function sub_reals(s::AbstractString)
  r = r"r([pn])\(([+-]?\d),([,\d]+)\)"
  for m in eachmatch(r, s)
    pos = m.captures[1] == "p"
    n = parse(Int, m.captures[2]) #exponent
    ds = map(x->parse(Int,x), split(m.captures[3], ",")) #digits
    real_number = pos ? rp(n, ds...) : rn(n, ds...)
    s = replace(s, m.match, signif(real_number, 5)) #round to 5 significant digits
  end
  return s
end

end #module
