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

module ExternalMetrics

export filestats, pairs_classifier, rand_index, error_index

using Iterators

function pairs_classifier(file::AbstractString; IdType::Type=Int64)
  dat = readcsv(file)
  idset = filter(x -> !isempty(x), unique(dat))
  convert(Vector{IdType}, idset)
  sort!(idset)
  out = Dict{(IdType, IdType), Bool}()
  for ids in subsets(idset, 2)
    id1, id2 = ids
    out[(id1, id2)] = false
  end
  mapslices(dat, 2) do v #each row
    filter!(x -> !isempty(x), v) #filter out ""
    if length(v) >= 2
      for ids in subsets(v, 2) #all pairs
        id1, id2 = sort(ids)
        out[(id1, id2)] = true
      end
    end
  end
  return out::Dict{(IdType, IdType), Bool}
end

function rand_index{T}(a1::Dict{(T, T), Bool}, a2::Dict{(T, T), Bool})
  @assert length(a1) == length(a2)
  samecount = count(x -> a2[x[1]] == x[2], a1)
  totalcount = length(a1)
  return samecount / totalcount
end

error_index{T}(a1::Dict{(T, T), Bool}, a2::Dict{(T, T), Bool}) = 1 - rand_index(a1, a2)

function filestats{T<:AbstractString}(files::Vector{T}; evalfunction::Function=pairs_classifier,
                              distance::Function=error_index)
  XS = map(evalfunction, files)
  num_xs = length(XS)
  M = zeros(num_xs, num_xs)
  for i = 1:num_xs, j = i:num_xs #upper triangular
    M[i, j] = M[j, i] = distance(XS[i], XS[j]) #symmetric
  end
  return M
end

end #module
