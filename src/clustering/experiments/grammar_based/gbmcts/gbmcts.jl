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

include(Pkg.dir("RLESCAS/src/clustering/clustering.jl")) #clustering packages
include(Pkg.dir("RLESCAS/src/clustering/experiments/grammar_based/grammar_typed/GrammarDef.jl")) #grammar

using GrammarDef
using DerivationTrees
using DerivationTreeVis
using TikzQTrees


################
###callbacks for vis
function get_name(node::DerivTreeNode)
  cmd_text = "cmd=$(node.cmd)"
  type_text = "type=$(split(string(typeof(node.rule)),".")[end])"
  depth_text = "depth=$(node.depth)"
  action_text = "action=$(node.action)"
  value_text = "value=$(string(getvalue(node)))"
  text = join([cmd_text, type_text, depth_text, action_text, value_text], "\\\\")
  return text::ASCIIString
end

get_height(node::DerivTreeNode) = node.depth
##############

function sample(; seed::Int64=1)
  srand(seed)

  grammar = create_grammar()
  params = DerivTreeParams(grammar)
  tree = DerivationTree(params)

  initialize!(tree)
  i = 1
  while !isterminal(tree) && i < 500
    println("step ", i)
    action_space = actionspace(tree)
    a = rand(action_space)
    step!(tree, a)
    i += 1
  end

  viscalls = VisCalls(get_name, get_height)
  fileroot = "tree_$seed"
  write_d3js(tree, viscalls, "$fileroot.json")
  plottree("$fileroot.json", outfileroot=fileroot)

  return tree
end
