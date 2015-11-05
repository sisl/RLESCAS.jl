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
using SKClustering
using CRVisualize
using PhylogeneticTrees
using DynamicTimeWarp
using Iterators

const NCLUSTERS = 5

feature_map = LookupCallback[
  LookupCallback("ra_detailed.ra_active", bool),
  LookupCallback("ra_detailed.ownInput.dz"),
  LookupCallback(["ra_detailed.ownInput.z", "ra_detailed.intruderInput[1].z"], (z1, z2) -> z2 - z1),
  LookupCallback("ra_detailed.ownInput.psi"),
  LookupCallback("ra_detailed.intruderInput[1].sr"),
  LookupCallback("ra_detailed.intruderInput[1].chi"),
  LookupCallback("ra_detailed.intruderInput[1].cvc"),
  LookupCallback("ra_detailed.intruderInput[1].vrc"),
  LookupCallback("ra_detailed.intruderInput[1].vsb"),
  LookupCallback("ra_detailed.ownOutput.cc"),
  LookupCallback("ra_detailed.ownOutput.vc"),
  LookupCallback("ra_detailed.ownOutput.ua"),
  LookupCallback("ra_detailed.ownOutput.da"),
  LookupCallback("ra_detailed.ownOutput.target_rate"),
  LookupCallback("ra_detailed.ownOutput.crossing", bool),
  LookupCallback("ra_detailed.ownOutput.alarm", bool),
  LookupCallback("ra_detailed.ownOutput.alert", bool),
  #LookupCallback("ra_detailed.ownOutput.dh_min"), #remove for now: the -9999 flag may be problematic
  #LookupCallback("ra_detailed.ownOutput.dh_max"), #remove for now: the 9999 flag may be problematic
  LookupCallback("ra_detailed.ownOutput.ddh"),
  LookupCallback("ra_detailed.intruderOutput[1].cvc"),
  LookupCallback("ra_detailed.intruderOutput[1].vrc"),
  LookupCallback("ra_detailed.intruderOutput[1].vsb"),
  LookupCallback("ra_detailed.intruderOutput[1].tds"),
  #LookupCallback("ra_detailed.intruderOutput[1].code"), #remove for now: this is categorical, needs special attn
  LookupCallback("response.state", x -> x == "none"), #split categorical to 1-hot
  LookupCallback("response.state", x -> x == "stay"), #split categorical to 1-hot
  LookupCallback("response.state", x -> x == "follow"), #split categorical to 1-hot
  LookupCallback("response.timer"),
  LookupCallback("response.h_d"),
  LookupCallback("response.psi_d")
  ]

files = readdir_ext("csv", "../data/dasc_nmacs") |> sort! #csvs
file_mat = hcat(groupby(x -> split(x, "_aircraft")[1], files)...)

gzfiles = map(file_mat[1, :]) do f
  string(split(f, "_aircraft")[1], ".json.gz")
end |> vec

#fmat = feature_matrix
fmats_by_file = feature_matrix(file_mat, feature_map)
fmats_by_encounter_raw = [vcat(fmats_by_file[:, i]...) for i = 1:size(fmats_by_file, 2)] #stack aircraft together

#stack encounters together (time-stripped). Combined raw dataset features(rows) by record(cols)
feats_combined_raw = hcat(fmats_by_encounter_raw...)

open("raw_features.csv", "w") do f
  writecsv(f, feats_combined_raw)
end

#scale features to [0,1]
feats_combined = similar(feats_combined_raw)
minmax = extrema(feats_combined_raw, 2)
for r = 1:size(feats_combined_raw, 1)
  xmin, xmax = minmax[r]
  feats_combined[r, :] = map(x -> scale01(x, xmin, xmax), feats_combined_raw[r, :])
end

open("processed_features.csv", "w") do f
  writecsv(f, feats_combined)
end

fmats_by_encounter = map(fmats_by_encounter_raw) do X
  out = similar(X)
  for r = 1:size(X, 1)
    xmin, xmax = minmax[r]
    out[r, :] = map(x -> scale01(x, xmin, xmax), X[r, :])
  end
  return out
end

vecvec{T}(M::Array{T, 2}) = [[M[:, i]] for i = 1:size(M, 2)] #convert 2D array to vector of vectors
squared_dist(x::Vector{Float64}, y::Vector{Float64}) = dot((x - y), (x - y)) #squared dist of two vectors
distance{T}(M1::Array{T, 2}, M2::Array{T, 2}) = dtw(vecvec(M1), vecvec(M2), squared_dist)[1] #distance between two feature matrices
tic()
A = symmetric_affinity(fmats_by_encounter, distance)
println("Compute affinity matrix: $(toq()) wall seconds")

tic()
result = agglomerative_cluster(gzfiles, A, NCLUSTERS)
println("Sklearn clustering: $(toq()) wall seconds")

save_result(result, "cluster_feats_dtw.json")
plot_to_file(result, outfileroot="cluster_feats_dtw")

nametable = [13,19,27,29,39,4,45,50,55,61,64,7,72,73,84,9,97,99]
open("featsdtw.txt", "w") do f
  writecsv(f, result, nametable=nametable)
end

nametable = map(x->string("enc$x"), nametable)
vis_from_distances(result.affinity, nametable=nametable, outfileroot="phylotree_feats_dtw")
