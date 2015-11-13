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

function plot_qtree(fcrules::FCRules, Dl::DFSetLabeled, title::String; outfileroot::String="crvis-qtree")
  qtree = to_qtree(fcrules, Dl, title)
  plottree(qtree, outfileroot=outfileroot)
end

function to_qtree(fcrules::FCRules, Dl::DFSetLabeled, title::String)
  colnames = get_colnames(Dl)
  root_text = "$title\\$(join(Dl.names,","))" |> escape_latex
  root = QTreeNode(root_text)
  sorted_labels = keys(fcrules.rules) |> collect |> sort!
  for label in sorted_labels
    classifier = fcrules.rules[label]
    code_text = pretty_string(string(classifier.code), colnames)
    members_text = get_members_text(Dl, label, classifier)
    cluster_text = "cluster=$label\\$(code_text)\\$(members_text)" |> escape_latex
    push!(root.children, QTreeNode(cluster_text))
  end
  return TikzQTree(root)
end

function get_members_text(Dl::DFSetLabeled, label, classifier::GBClassifier)
  members = find(Dl.labels .== label)
  ss = Dl.names[members]
  s = join(ss, ",") #TODO: also list mismatches
  return s
end

function write_d3js(hcrules::HCRules, Dl::DFSetLabeled; outfileroot::String="crvis-d3js")
  d = to_d3js(hcrules, Dl, title)
  filename = join(outfileroot, ".json")
  f = open(filename, "w")
  JSON.print(f, d)
  close(f)
  return filename
end

function to_d3js(hcrules::HCRules, Dl::DFSetLabeled)
  root = hcrules.rules[end]
  d = Dict{ASCIIString,Any}() #JSON-compatible
  process!(d, root)
  return d
end

function process!(d::Dict{ASCIIString,Any}, hcrules::HCRules, index::Int64)
  node = hcrules.rules[index]
  d["name"] = "$(node.members)\n$(node.classifier.code)"
  d["height"] = index
  d["children"] = Array(Dict{ASCIIString,Any}, 0)
  dchild = d["children"]
  for (bool, child_index) in node.children
    push!(d_child, Dict{ASCIIString,Any}())
    process!(d_child[end], hcrules, child_index)
  end
end

#name, height, children::Vector{Dict{String,Any}}

end #module


