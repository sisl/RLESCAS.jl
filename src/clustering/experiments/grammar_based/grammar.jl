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

using GrammaticalEvolution
using DataFrames

typealias RealVec Union(DataArray{Float64,1}, Vector{Float64})

convert_number(lst) = float(join(lst))

function create_grammar()
  @grammar grammar begin
    start = Expr(:call, :now, top)

    top = top_and | top_or | top_not | always | eventually | until | weakuntil | release
    top_and = Expr(:call, :&, top, top)
    top_or = Expr(:call, :|, top, top)
    top_not = Expr(:call, :!, top)

    #produces a bin_vec
    bin_vec = bin_feat_vec | and | or | not | always | eventually | until | weakuntil | release | implies | next | eq | lt | lte | diff_eq | diff_lt | diff_lte | sign | count
    and = Expr(:call, :&, bin_vec, bin_vec)
    or = Expr(:call, :|, bin_vec, bin_vec)
    not = Expr(:call, :!, bin_vec)
    always = Expr(:call, :G, bin_vec) #global
    eventually = Expr(:call, :F, bin_vec) #future
    until = Expr(:call, :U, bin_vec, bin_vec) #until
    weakuntil = Expr(:call, :W, bin_vec, bin_vec) #weak until
    release = Expr(:call, :R, bin_vec, bin_vec) #release
    implies = Expr(:call, :Y, bin_vec, bin_vec)
    next = Expr(:call, :X, bin_vec) #next
    eq = Expr(:comparison, real_feat_vec, :.==, real_number) | Expr(:comparison, real_feat_vec, :.==, real_feat_vec)
    lt = Expr(:comparison, real_feat_vec, :.<, real_number) | Expr(:comparison, real_feat_vec, :.<, real_feat_vec) | Expr(:comparison, real_number, :.<, real_feat_vec)
    lte = Expr(:comparison, real_feat_vec, :.<=, real_number) | Expr(:comparison, real_feat_vec, :.<=, real_feat_vec) | Expr(:comparison, real_number, :.<=, real_feat_vec)
    diff_eq = Expr(:call, :dfeq, real_feat_vec, real_feat_vec, real_number)
    diff_lt = Expr(:call, :dflt, real_feat_vec, real_feat_vec, real_number)
    diff_lte = Expr(:call, :dfle, real_feat_vec, real_feat_vec, real_number)
    sign = Expr(:call, :sn, real_feat_vec, real_feat_vec)
    count = Expr(:call, :ctlt, bin_vec, real_number) | Expr(:call, :ctle, bin_vec, real_number) | Expr(:call, :ctgt, bin_vec, real_number) | Expr(:call, :ctge, bin_vec, real_number) | Expr(:call, :cteq, bin_vec, real_number)

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
diff_eq(v1::RealVec, v2::RealVec, b::Float64) = (v1 - v2) .== b
diff_lte(v1::RealVec, v2::RealVec, b::Float64) = (v1 - v2) .<= b
diff_lt(v1::RealVec, v2::RealVec, b::Float64) = (v1 - v2) .< b

eventually(v::AbstractVector{Bool}) = Bool[any(v[t:end]) for t = 1:endof(v)]
globally(v::AbstractVector{Bool}) = Bool[all(v[t:end]) for t = 1:endof(v)]

function until(v1::AbstractVector{Bool}, v2::AbstractVector{Bool})
  v = similar(v1)
  for t = 1:endof(v)
    t1 = findfirst(v2[t:end])
    v[t] = t1 > 0 ? all(v1[t:t1-1]) : false
  end
  return v
end

weak_until(v1::AbstractVector{Bool}, v2::AbstractVector{Bool}) = until(v1, v2) | globally(v1)
release(v1::AbstractVector{Bool}, v2::AbstractVector{Bool}) = weak_until(v2, v2 & v1) #v1 releases v2
next_(v::AbstractVector{Bool}) = vcat(v[2:end], false)
implies(v1::AbstractVector{Bool}, v2::AbstractVector{Bool}) = !v1 | v2

sign_(v1::RealVec, v2::RealVec) = (sign(v1) .* sign(v2)) .>= 0.0 #same sign, 0 matches any sign
count_(v::AbstractVector{Bool}) = Float64[count(identity, v[t:end]) for t = 1:endof(v)]
count_eq(v::AbstractVector{Bool}, b::Float64) = count_(v) .== b
count_lt(v::AbstractVector{Bool}, b::Float64) = count_(v) .< b
count_lte(v::AbstractVector{Bool}, b::Float64) = count_(v) .<= b
count_gt(v::AbstractVector{Bool}, b::Float64) = count_(v) .> b
count_gte(v::AbstractVector{Bool}, b::Float64) = count_(v) .>= b

#shorthands used in grammar
now = first
rn = get_real
dfeq = diff_eq
dfle = diff_lte
dflt = diff_lt
F = eventually
G = globally
U = until
W = weak_until
R = release
X = next_ #avoid conflict with Base.next
Y = implies
sn = sign_ #avoid conflict with Base.sign
ctlt = count_lt
ctle = count_lte
ctgt = count_gt
ctge = count_gte
cteq = count_eq

get_col_types(D::DataFrame) = [typeof(D.columns[i]).parameters[1] for i=1:length(D.columns)]
function make_type_string(D::DataFrame)
  Ts = map(string, get_col_types(D))
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

function sub_varnames{T<:String}(s::String, colnames::Vector{T})
  r = r"D\[:,([0-9]+)\]"
  for m in eachmatch(r, s)
    id = m.captures[1] |> int
    s = replace(s, m.match, colnames[id])
  end
  return s
end
