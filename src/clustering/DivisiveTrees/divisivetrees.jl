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

module DivisiveTrees

export DTSet, DTParams, DivisiveTree, DTNode, build_tree, classify, entropy, gain, gains, maxgain

type DTSet{T}
  records::Vector{T}
end

type DTParams
  get_rule::Function #get_rule(S, records)
  predict::Function #predict(split_rule, S, records)
  stopcriterion::Function
  nclusters::Int64 #counter state, not an input
end
DTParams(get_rule::Function, predict::Function, stopcriterion::Function) = DTParams(get_rule, predict, stopcriterion, 0)

type DTNode
  split_rule::Any #splits into true/false
  members::Vector{Int64} #index into input
  children::Dict{Any, DTNode} #key=split result, value=child node
  label::Any #nothing for non-leaf, otherwise the predicted class label
  depth::Int64 #depth into tree (root at 0)
end
DTNode() = DTNode(nothing, Int64[], Dict{Bool, DTNode}(), nothing, 0)

type DivisiveTree
  root::DTNode
end

#Attributes is records (rows) by attribute (cols)
function build_tree(S::DTSet, p::DTParams)
  allrecords = [1:length(S.records)]
  root = DTNode()
  process_node!(root, S, allrecords, p)
  return DivisiveTree(root)
end

function process_node!(node::DTNode, S::DTSet, records::Vector{Int64}, p::DTParams)
  node.members = deepcopy(records)
  empty!(node.children)
  node.split_rule = p.get_rule(S, records)
  split_result = p.predict(node.split_rule, S, records)
  splitset = unique(split_result)
  #all labels are the same or user stopping
  if length(splitset) == 1 ||
      p.stopcriterion(split_result, node.depth, p.nclusters)
    node.split_rule = nothing
    node.label = nextlabel!(p) #no more splits
  else
    node.label = nothing #not a leaf
    for val in splitset
      node.children[val] = child = DTNode()
      child.depth = node.depth + 1
      ids = find(x -> x == val, split_result)
      childrecords = records[ids]
      process_node!(child, S, childrecords, p) #recurse on child
    end
  end
  return
end

function classify(node::DTNode, record::Any, rules::Vector{Any})
  if node.label != nothing
    return (node.label, rules)
  end
  push!(rules, node.split_rule)
  split_result = p.predict(node.split_rule, record)
  child = node.children[split_result]
  return classify(child, record)
end
function classify(dtree::DivisiveTree, record::Any)
  rules = Array(Any, 0)
  return classify(dtree.root, record, rules)
end

nextlabel!(p::DTParams) = p.nclusters += 1

end #module
