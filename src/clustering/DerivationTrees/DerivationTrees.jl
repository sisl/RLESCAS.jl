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

#Derivation tree for GrammaticalEvolution
#Warning: not all rules are supported
module DerivationTrees

export DerivTreeParams, DerivationTree, DerivTreeNode

using GrammaticalEvolution
using DataStructures

typealias DecisionRule Union{OrRule, RangeRule} #rules that require a decision

type DerivTreeParams
  grammar::Grammar
end

type DerivTreeNode
  cmd:::ASCIIString
  rule::Rule
  value #FIXME: Type this
  depth::Int64
  children::Vector{DerivTreeNode}
end
function DerivTreeNode(cmd::ASCIIString, rule::Rule, depth::Int64)
  return DerivTreeNode(cmd, rule, 0, depth, DerivTreeNode[])
end

type DerivationTree
  params::DerivTreeParams
  root::DerivTreeNode
  opennodes::Stack
end
DerivationTree(p::DerivTreeParams) =
  DerivationTree(p, DerivTreeNode(), Stack(DerivTreeNode))


using Debug
@debug function initialize(tree::DerivationTree)
  @bp
  p = tree.params
  tree.root = node = DerivTreeNode("start", p.grammar.rules[:start])
  push!(tree.opennodes, node)
  process_non_decisions!(tree)
end

@debug function step(tree::DerivationTree, a::Int64)
  @bp
  if isempty(opennodes)
    return #we're done
  end
  node = pop!(opennodes)
  process!(tree, node, node.rule, a)
  process_non_decisions!(tree)
end

isterminal(tree::DerivationTree) = isempty(tree.opennodes)

@debug function process_non_decisions!(tree::DerivationTree)
  @bp
  opennodes = tree.opennodes
  while !isempty(opennodes) && !issubtype(top(opennodes).rule, DecisionRule)
    @bp
    node = pop!(opennodes)
    process!(tree, node, node.rule)
  end
end

@debug function process!(tree::DerivationTree, node::DerivTreeNode, rule::OrRule, a::Int64)
  @bp
  idx = (a % length(rule.values)) + 1
  child_node = DerivTreeNode(rule.name, rule.values[idx], node.depth + 1)
  push!(node.children, child_node)
  push!(tree.opennodes, child_node)
end

@debug function process!(tree::DerivationTree, node::DerivTreeNode, rule::RangeRule, a::Int64)
  @bp
  node.value = (a % length(rule.range)) + rule.range.start
end

@debug function process!(tree::DerivationTree, node::DerivTreeNode, rule::ReferencedRule)
  @bp
  p = tree.params
  child_node = DerivTreeNode(rule.name, p.grammar.rules[rule.symbol], node.depth + 1)
  push!(node.children, child_node)
  push!(tree.opennodes, child_node)
end

@debug function process!(tree::DerivationTree, node::DerivTreeNode, rule::AndRule)
  @bp
  for subrule in rule.values
    @bp
    child_node = DerivTreeNode(rule.name, subrule, node.depth + 1)
    push!(node.children, child_node)
    push!(tree.opennodes, child_node)
  end
end

@debug function process!(tree::DerivationTree, node::DerivTreeNode, rule::ExprRule)
  @bp
  for arg in rule.args
    @bp
    child_node = DerivTreeNode(rule.name, arg, node.depth + 1)
    push!(node.children, child_node)
    push!(tree.opennodes, child_node)
  end
end

@debug function process!(tree::DerivationTree, node::DerivTreeNode, sym::Symbol)
  @bp
  node.value = sym
end

@debug function process!(tree::DerivationTree, node::DerivTreeNode, rule::Terminal)
  @bp
  node.value = rule.value
end

end #module
