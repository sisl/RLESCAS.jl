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

include(Pkg.dir("RLESCAS/src/clustering/clustering.jl"))

using RLESUtils.FileUtils
using RLESUtils.StringUtils #hamming
using JSON2ASCII
using ClusterResults
using SKClustering
using CRVisualize
using Levenshtein

const NCLUSTERS = 5
const FIELDS = ASCIIString["sensor", "ra_detailed", "response", "adm"]

files = readdir_ext("gz", "../../data/dasc_nmacs/json")

tic() #CPUtime doesn't work well for parallel
X = pmap(f -> extract_string(f, FIELDS), files)
X = convert(Vector{ASCIIString}, X)
println("Extract string: $(toq()) wall seconds")

#compute affinity matrix
tic()
A = symmetric_affinity(X, levenshtein)
#A = symmetric_affinity(X, hamming) #hamming
println("Compute affinity matrix: $(toq()) wall seconds")

tic()
result = agglomerative_cluster(files, A, NCLUSTERS)
println("Sklearn clustering: $(toq()) wall seconds")

save_result(result, "asciicluster_leven.json")
plot_to_file(result, outfileroot="asciicluster_leven")
#save_result(result, "asciicluster_hamming.json") #hamming
#plot_to_file(result, outfileroot="asciicluster_hamming") #hamming

