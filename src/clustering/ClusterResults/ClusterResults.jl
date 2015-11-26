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

module ClusterResults

export ClusterResult, save_result, load_result, to_sorted_list, by_label, save_csv, load_csv

using JSON
using RLESUtils.Obj2Dict
using Iterators

type ClusterResult
  names::Vector{ASCIIString}
  labels::Vector{Int64}
  n_clusters::Int64
  affinity::Array{Float64, 2} #empty if not used
  tree::Array{Int32, 2} #empty if not used
end
ClusterResult() = ClusterResult(ASCIIString[], Int64[], -1, Array(Float64, 0, 0),
                                  Array(Int32, 0, 0))

function ==(x1::ClusterResult, x2::ClusterResult)
  for sym in names(ClusterResult)
    if x1.(sym) != x2.(sym)
      return false #any field that doesn't match, return false
    end
  end
  return true #all fields must match to return true
end

function save_result(result::ClusterResult, outfile::AbstractString="cluster_result.json")
  f = open(outfile, "w")
  d = Obj2Dict.to_dict(result)
  JSON.print(f, d)
  close(f)
  return outfile
end

function load_result(file::AbstractString="cluster_result.json")
  f = open(file)
  d = JSON.parse(f)
  close(f)
  return Obj2Dict.to_obj(d)
end

function to_sorted_list(affinity_matrix::Array{Float64, 2},
                        nametable::Vector{ASCIIString}=ASCIIString[];
                        outfile::AbstractString="sorted.txt")
  A = affinity_matrix
  nrows, ncols = size(A)
  @assert nrows == ncols
  n = nrows
  nelements = convert(Int64, n * (n - 1) / 2)
  out = Array((ASCIIString, ASCIIString, Float64), nelements)

  k = 1
  for i = 1:n
    for j = (i + 1):n
      namei = !isempty(nametable) ? nametable[i] : "$i"
      namej = !isempty(nametable) ? nametable[j] : "$j"
      out[k] = (namei, namej, A[i, j])
      k += 1
    end
  end
  sort!(data, by=x->x[3]) #sort by metric

  #write result to file
  f = open(outfile, "w")
  for entry in data
    println(f, entry)
  end
  close(f)

  return out
end

function to_sorted_list(result::ClusterResult; outfile::AbstractString="sorted.txt")
  to_sorted_list(result.affinity, convert(Vector{ASCIIString}, result.names), outfile)
end

function by_label(result::ClusterResult, label)
  inds = find(x -> x == label,result.labels)
  return result.names[inds]
end

function save_csv{T}(io::IO, result::ClusterResult; nametable::Vector{T}=[])
  if isempty(nametable) #use default if nametable is not provided
    nametable = result.names
  end
  A = sort(collect(zip(nametable, result.labels)), by=x -> x[2])
  B = groupby(x -> x[2], A) |> collect
  maxlen = map(x -> length(x), B) |> maximum
  D = fill("", (result.n_clusters, maxlen))
  for (i, v) in enumerate(B)
    D[i, 1:length(v)] = map(x -> string(x[1]), v)
  end
  writecsv(io, D)
end

function load_csv(io::IO)
  result = ClusterResult()
  i = 0
  for line in readlines(io)
    i += 1
    arr = split(chomp(line), ",") |> sort!
    push!(result.names, arr...)
    push!(result.labels, repeated(i, length(arr))...)
  end
  result.n_clusters = i
  return result
end

end #module
