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

#Force-directed D3 visualization
#output to JSON

#Format:
#top-level Dict d
#d is Dict{ASCIIString,Any} has two fields: "nodes" and "links"
#d["nodes"] is an array of Dict{ASCIIString,Any}
#d["nodes"][1] has two fields "name" and "group"
#d["nodes"][1]["name"] = name of node as a string
#d["nodes"][1]["group"] = group label as an int
#d["links"] is an array of Dict{ASCIIString,Any}
#d["links"][1] has 3 fields "source", "target", "value"
#d["links"][1]["source"] = index of array of source node (0-indexing)
#d["links"][1]["target"] = index of array of target node (0-indexing)
#d["links"][1]["value"] = force of link

include("../clustering.jl")
using Clustering

using JSON

force_directed(cr::ClusterResults) = force_directed(cr.files, cr.labels, cr.affinity)

function force_directed{T<:AbstractString}(names::Vector{T}, labels::Vector{Int},
                                   affinity::Array{Float64,2};
                                       outfile::AbstractString="force_directed.json")
    d = Dict{ASCIIString,Any}()
    d["nodes"] = Dict{ASCIIString,Any}[]
    d["links"] = Dict{ASCIIString,Any}[]

    for (name, label) in zip(names, labels)
        node = Dict{ASCIIString,Any}(["name" => name,
                                       "group" => label])
        push!(d["nodes"], node)
    end

    #force function
    F = 1 ./ affinity.^2
    minval, maxval = extrema(filter(x->x!=Inf, F[:])) #min/max excluding 0.0s
    F = 0.1 * ((F - minval) ./ (maxval - minval))
    f(i, j) = F[i, j]

    for i = 1:size(affinity, 1) #rows
        for j = (i + 1):size(affinity, 2) #cols, upper triangular only
            node = Dict{ASCIIString,Any}(["source" => i - 1,
                                          "target" => j - 1,
                                          "value" => f(i, j)])
            push!(d["links"], node)
        end
    end

    f = open(outfile, "w")
    JSON.print(f, d)
    close(f)

    d
end
