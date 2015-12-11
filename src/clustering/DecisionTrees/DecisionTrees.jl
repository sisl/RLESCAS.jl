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

export DTParams, DecisionTree, DTNode, build_tree, classify, isleaf, get_max_depth

using StatsBase

type DTParams
  num_data::Int64 #number of datapoints in training set
  get_truth::Function #labels = get_truth(members)
  get_splitter::Function #split_rule = get_splitter(members)
  get_labels::Function #labels = get_labels(split_rule,members)
  maxdepth::Int64
  predict_type::Type #T1
  label_type::Type #T2
end

type DTNode{T1,T2}
  depth::Int64
  members::Vector{Int64} #indices into data starting at 1
  split_rule::Any #object used in callback for split rule
  children::Dict{T1,DTNode{T1,T2}} #key=split_rule predicts, value=child node, T1=predict label type
  label::T2 #T2=label type
  confidence::Float64
end

type DecisionTree{T1,T2}
  root::DTNode{T1,T2}
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
  label = mode(labels)
  confidence = proportions(labels, label:label)[1] #proportion of times label appears
  T1 = p.predict_type
  T2 = p.label_type
  @assert issubtype(eltype(labels), T2)
  children = Dict{T1,DTNode{T1,T2}}()
  if confidence == 1.0 || depth >= p.maxdepth #all outputs same, or reached stopping criterion
    split_rule = nothing
  else #consider splitting
    split_rule = p.get_splitter(members)
    if split_rule != nothing #get_splitter returns nothing if can't find a good split
      predict_labels = p.get_labels(split_rule, members)
      @assert issubtype(eltype(predict_labels), T1)
      predict_set = unique(predict_labels)
      child_nodes = map(predict_set) do label_class #TODO: parallelize, pmap crashes due to missing callbacks
        child_members = members[find(x -> x == label_class, predict_labels)]
        child = process_child(p, child_members, depth + 1)
        return child
      end
      for (label_class, child_node) in zip(predict_set, child_nodes)
        children[label_class] = child_node
      end
    end
  end
  node = DTNode{T1,T2}(depth, members_copy, split_rule, children, label, confidence)
  return node
end

classify{T1,T2}(p::DTParams, tree::DecisionTree{T1,T2}, x) = classify(p, tree.root, x) #x could be either id or data
function classify{T1,T2}(p::DTParams, node::DTNode{T1,T2}, x)
  if isempty(node.children) #leaf node
    return node.label::T1
  end
  label = p.get_labels(node.split_rule, [x])[1]
  child = node.children[label]
  return classify(child, x)
end

isleaf{T1,T2}(node::DTNode{T1,T2}) = isempty(node.children)

get_max_depth{T1,T2}(dtree::DecisionTree{T1,T2}) = get_max_depth(dtree.root)
function get_max_depth{T1,T2}(node::DTNode{T1,T2})
  if isleaf(node)
    return node.depth
  else
    return map(get_max_depth, values(node.children)) |> maximum
  end
end

end #module
