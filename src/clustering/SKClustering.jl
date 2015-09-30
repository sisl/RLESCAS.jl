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

module SKClustering

export agglomerative_cluster, symmetric_affinity, full_affinity

using PyCall
using ClusterResults

@pyimport sklearn.cluster as skcluster

function agglomerative_cluster{T<:String}(affinity::Array{Float64, 2}, n_clusters::Int)
  #returns a PyObject
  model = skcluster.AgglomerativeClustering(n_clusters=n_clusters,
                                            affinity="precomputed",
                                            linkage="average",
                                            compute_full_tree=true)

  tic()
  model[:fit](affinity)
  println("Sklearn clustering: $(toq()) wall seconds")

  labels = model[:labels_]
  tree = model[:children_]
  return ClusterResult(files, labels, n_clusters, affinity, tree)
end

function symmetric_affinity{T}(X::Vector{T}, distance::Function)
  indmatrix = [(i, j) for i = 1:length(X), j = 1:length(X)]

  #compute for upper triangular in parallel
  #diag and lower triangular are zero
  A = pmap(ij -> begin
              i, j = ij
              i < j ? distance(X[i], X[j]) : 0.0
           end,
           indmatrix)
  A = reshape(A, length(X), length(X))

  #copy lower triangular from upper
  for i = 1:length(X)
    for j = 1:(i-1)
      A[i, j] = A[j, i]
    end
  end
  return convert(Array{Float64, 2}, A) #affinity matrix aka distance matrix
end

function full_affinity{T}(X::Vector{T}, distance::Function)
  indmatrix = [(i, j) for i = 1:length(X), j = 1:length(X)]
  A = pmap(ij -> begin #diags are zero
              i, j = ij
              i != j ? distance(X[i], X[j]) : 0.0
           end,
           indmatrix)
  A = reshape(A, length(X), length(X))
  return convert(Array{Float64, 2}, A) #affinity matrix aka distance matrix
end

end #module
