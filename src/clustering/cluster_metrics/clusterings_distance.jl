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

module ClusteringsDistance

export get_pairs_set, filestats, setdist, get_adjacency, adj_dist

using RLESUtils.FileUtils
using Iterators

function get_pairs_set(file::String)
  dat = readcsv(file)
  pairsset = Set() #set of id pairs in the same cluster
  mapslices(dat, 2) do v #returns each row
    filter!(x->!isempty(x), v)
    if length(v) >= 2
      for id_pair in subsets(v, 2) #all pairs
        sort!(id_pair)
        push!(pairsset, tuple(id_pair...))
      end
    end
  end
  return pairsset
end

function get_adjacency(file::String)
  dat = readcsv(file)
  idset = filter(x -> !isempty(x), unique(dat))
  sort!(idset)
  reversemap = Dict{Any, Int64}()
  for (i, id) in enumerate(idset)
    reversemap[id] = i
  end
  adjacency = zeros(Bool, length(idset), length(idset))
  mapslices(dat, 2) do v #each row
    filter!(x->!isempty(x), v)
    if length(v) >= 2
      for ids in subsets(v, 2) #all pairs
        id1, id2 = ids
        i = haskey(reversemap, id1) ? reversemap[id1] : error("key not found: $id1")
        j = haskey(reversemap, id2) ? reversemap[id2] : error("key not found: $id2")
        adjacency[i, j] = adjacency[j, i] = true
      end
    end
  end
  return adjacency
end

set_dist(s1::Set, s2::Set) = length(intersect(s1, s2))
function adjacency_dist(a1::Array{Bool, 2}, a2::Array{Bool, 2})
  diffcount = count(identity, a1 .!= a2) / 2 #div by 2 since symmetric
  @assert size(a1) == size(a2) && size(a1, 1) == size(a1, 2)
  totalcount = (length(a1) - size(a1, 1)) / 2
  return diffcount / totalcount
end

function filestats{T<:String}(files::Vector{T}; evalfunction::Function=get_adjacency,
                              dist::Function=adjacency_dist)
  XS = map(evalfunction, files)
  num_xs = length(XS)
  M = zeros(num_xs, num_xs)
  for i = 1:num_xs, j = 1:num_xs
    if i <= j
      M[i, j] = dist(XS[i], XS[j])
    else
      M[i, j] = M[j, i] #symmetric
    end
  end
  return M
end

end #module
