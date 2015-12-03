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

#Generic decision tree based on callbacks
module DecisionTrees

export DTParams. DecisionTree, build_tree, classify

using StatsBase

type DTParams
  num_data::Int64 #number of datapoints in training set
  get_truth::Function #labels = get_truth(members)
  get_splitter::Function #split_rule = get_splitter(members)
  get_labels::Function #labels = get_labels(split_rule)
  maxdepth::Int64
end

type DTNode{T}
  members::Vector{Int64} #indices into data starting at 1
  split_rule::Any #object used in callback for split rule
  children::Dict{T,DTNode} #key=value of label, value=child node
  label::Union{Void,T}
end

type DecisionTree
  root::DTNode
end

function build_tree(p::DTParams)
  members = collect(1:p.num_data)
  depth = 0
  root = process_child(p, members, depth)
  return DecisionTree(root)
end

function process_child(p::DTParams, members::Vector{Int64}, depth::Int64)
  members_copy = deepcopy(members)
  labels = p.get_truth(members)
  labelset = unique(labels)
  T = eltype(labelset)
  if length(labelset) == 1 #all outputs are the same
    label = labelset[1]
    children = Dict{T,DTNode}() #leaf
    node = DTNode(members_copy, nothing, children, label)
  elseif depth >= p.maxdepth #reached stopping criterion
    label = mode(labels) #from StatsBase.jl
    children = Dict{T,DTNode}() #leaf
    node = DTNode(members_copy, nothing, children, label)
  else
    label = nothing
    split_rule = p.get_splitter(members)
    predict_labels = p.get_labels(split_rule, members)
    children = Dict{T,DTNode}()
    for label in unique(predict_labels)
      child_members = predict_labels[find(x -> x == label, predict_labels)]
      children[label] = process_child(p, child_members, depth + 1)
    end
    node = DTNode(members_copy, split_rule, children, label)
  end
  return node
end

classify(p::DTParams, tree::DecisionTree, x) = classify(p, tree.root, x) #x could be either id or data
function classify(p::DTParams, node::DTNode, x)
  if isempty(node.children) #leaf node
    return node.label
  end
  label = p.get_labels(node.split_rule, [x])[1]
  child = node.children[label]
  return classify(child, x)
end

end #module
