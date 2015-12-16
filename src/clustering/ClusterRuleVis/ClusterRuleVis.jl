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

module ClusterRulesVis

export to_qtree, plot_qtree, to_d3js, write_d3js

using GrammarDef
using ClusterRules
using GBClassifiers
using DataFrameSets
using TikzQTrees
using RLESUtils.LatexUtils
using JSON

function plot_qtree(fcrules::FCRules, Dl::DFSetLabeled; check_result::Union{Void, FCCheckResult}=nothing,
                    outfileroot::AbstractString="crvis-qtree")
  qtree = to_qtree(fcrules, Dl, check_result=check_result)
  plottree(qtree, outfileroot=outfileroot)
end

function to_qtree(fcrules::FCRules, Dl::DFSetLabeled; check_result::Union{Void, FCCheckResult}=nothing)
  colnames = get_colnames(Dl)
  root_text = "$(join(Dl.names,","))" |> escape_latex
  root = QTreeNode(root_text)
  sorted_labels = keys(fcrules.rules) |> collect |> sort!
  for label in sorted_labels
    classifier = fcrules.rules[label]
    label_text = "cluster=$label"
    code_text = pretty_string(string(classifier.code), colnames)
    members_text = get_members_text(Dl, label)
    checker_text = get_checker_text(Dl, label, check_result)
    combined_text = join([label_text, members_text, code_text, checker_text], "\\") |> escape_latex
    push!(root.children, QTreeNode(combined_text))
  end
  return TikzQTree(root)
end

function get_members_text{T}(Dl::DFSetLabeled{T}, label::T)
  members = find(Dl.labels .== label)
  ss = Dl.names[members]
  s = join(ss, ",")
  return s
end

function get_checker_text{T}(Dl::DFSetLabeled{T}, label::T, check_result::Union{Void,FCCheckResult})
  if check_result == nothing
    return ""
  end
  matched = Dl.names[check_result.result[label].matched]
  mismatched = Dl.names[check_result.result[label].mismatched]
  return "matches=$(join(matched, ","))\\mismatches=$(join(mismatched, ","))"
end

function get_checker_text{T}(Dl::DFSetLabeled{T}, index::Int64, check_result::Union{Void,HCCheckResult})
  if check_result == nothing
    return ""
  end
  matched = Dl.names[check_result.result[index].matched]
  mismatched = Dl.names[check_result.result[index].mismatched]
  return "matches=$(join(matched, ","))\nmismatches=$(join(mismatched, ","))"
end

function write_d3js(hcrules::HCRules, Dl::DFSetLabeled; check_result::Union{Void, HCCheckResult}=nothing,
                    outfileroot::AbstractString="crvis-d3js")
  d = to_d3js(hcrules, Dl, check_result=check_result)
  filename = "$(outfileroot).json"
  f = open(filename, "w")
  JSON.print(f, d)
  close(f)
  return filename
end

function to_d3js(hcrules::HCRules, Dl::DFSetLabeled; check_result::Union{Void, HCCheckResult}=nothing)
  colnames = get_colnames(Dl)
  root_index = length(hcrules.rules)
  d = Dict{ASCIIString,Any}() #JSON-compatible
  process!(d, Dl, hcrules, root_index, colnames, check_result)
  return d
end

function process!(d::Dict{ASCIIString,Any}, Dl::DFSetLabeled, hcrules::HCRules, index::Int64,
                  colnames::Vector{ASCIIString}, check_result::Union{Void, HCCheckResult}=nothing)
  node = hcrules.rules[index]
  members_text = join(node.members, ",")
  code_text = node.classifier != nothing ?
     pretty_string(string(node.classifier.code), colnames) : ""
  checker_text = get_checker_text(Dl, index, check_result)
  d["name"] = join([members_text, code_text, checker_text], "\n")
  merge_number = max(0, index - hcrules.ndata) #shift down, leafs at 0
  num_merges = size(hcrules.tree, 1)
  d["height"] =  num_merges - merge_number #from root
  d["children"] = Array(Dict{ASCIIString,Any}, 0)
  d_child = d["children"]
  for (bool, child_index) in node.children
    push!(d_child, Dict{ASCIIString,Any}())
    process!(d_child[end], Dl, hcrules, child_index, colnames)
  end
end

end #module


