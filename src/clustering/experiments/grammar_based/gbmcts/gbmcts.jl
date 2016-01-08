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
using Datasets
using DerivTreeMDPs
using DerivationTreeVis
using TikzQTrees
using DataFrameSets
using RLESUtils.Observers
using GrammaticalEvolution
using FastAnonymous

using MCTS

import DerivationTrees.isterminal

#const MANUALS = "dasc_manual"
#const DATASET = dataset("dasc")
#const DATASET_META = dataset("dasc_meta", "encounter_meta")
const DATASET = dataset("libcas098_small")
const DATASET_META = dataset("libcas098_small_meta", "encounter_meta")

const MAXSTEPS = 20
const DISCOUNT = 1.0
const MAXCODELENGTH = 1000000 #disable for now
const MAX_NEG_REWARD = -2000.0
const STEP_REWARD = -0.01 #use step reward instead of discount to not discount neg rewards

################
###callbacks for vis
function get_name(node::DerivTreeNode)
  cmd_text = "cmd=$(node.cmd)"
  type_text = "type=$(split(string(typeof(node.rule)),".")[end])"
  depth_text = "depth=$(node.depth)"
  action_text = "action=$(node.action)"
  value_text = "value=$(string(get_expr(node)))"
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

##################
function nmac_clusters(clustering::DataFrame, Ds::DFSet)
  ids = map(x -> parse(Int, x), names(Ds))
  labeldict = Dict{Int64,Int64}() #facilitate random access
  for row in eachrow(clustering)
    labeldict[row[:encounter_id]] = row[:label]
  end
  inds = find(x -> haskey(labeldict, x), ids)
  sublabels = map(x -> labeldict[x], ids[inds])
  subDs = Ds[inds]
  return DFSetLabeled(subDs, sublabels)
end

function nonnmacs_extra_cluster(clustering::DataFrame, Ds::DFSet, meta::DataFrame)
  ids = map(x -> parse(Int, x), names(Ds))
  labeldict = Dict{Int64,Int64}() #facilitate random access
  for row in eachrow(clustering)
    labeldict[row[:encounter_id]] = row[:label]
  end

  nmacdict = Dict{Int64,Bool}() #facilitate random access
  for row in eachrow(meta)
    nmacdict[row[:encounter_id]] = row[:nmac]
  end

  nonnmac_label = maximum(clustering[:label]) + 1
  labels = map(ids) do id
    label = if haskey(labeldict, id)
      labeldict[id]
    else
      @assert nmacdict[id] == false
      nonnmac_label
    end
    return label
  end
  return DFSetLabeled(Ds, labels)
end

function nmacs_vs_nonnmacs(Ds::DFSet, meta::DataFrame)
  ids = map(x -> parse(Int, x), names(Ds))
  nmac_ids = meta[meta[:nmac] .== true, :encounter_id]
  nonnmac_ids = meta[meta[:nmac] .== false, :encounter_id]
  labels = map(ids) do id
    label = if id in nmac_ids
      1
    elseif id in nonnmac_ids
      2
    else
      error("encounter id not found: $id")
    end
    return label
  end
  return DFSetLabeled(Ds, labels)
end

#############
function get_metrics{T}(predicts::Vector{Bool}, truth::Vector{T})
  true_ids = find(predicts)
  false_ids = find(!predicts)
  ent_pre = truth |> proportions |> entropy
  ent_true = !isempty(true_ids) ?
    truth[true_ids] |> proportions |> entropy : 0.0
  ent_false = !isempty(false_ids) ?
    truth[false_ids] |> proportions |> entropy : 0.0
  w1 = length(true_ids) / length(truth)
  w2 = length(false_ids) / length(truth)
  ent_post = w1 * ent_true + w2 * ent_false #miminize entropy after split
  info_gain = ent_pre - ent_post
  return (info_gain, ent_pre, ent_post) #entropy pre/post split
end

##############
const W_ENT = 100 #entropy
const W_LEN = 0.1 #
function get_fitness{T}(code::Union{Expr,Symbol}, Dl::DFSetLabeled{T})
  codelen = length(string(code))
  if codelen > MAXCODELENGTH #avoid long evaluations on long codes
    return realmax(Float64)
  end

  f = to_function(code)
  predicts = map(f, Dl.records)
  _, _, ent_post = get_metrics(predicts, Dl.labels)
  return W_ENT * ent_post + W_LEN * codelen
end

function tree_reward{T}(tree::DerivationTree, Dl::DFSetLabeled{T})
  reward = if iscomplete(tree)
    code = get_expr(tree)
    r = -get_fitness(code, Dl)
    #println("complete=", code)
    #println("reward=", r)
    r
  elseif isterminal(tree) #not-compilable
    #println("terminal reward=", MAX_NEG_REWARD)
    MAX_NEG_REWARD
  else #each step
    #STEP_REWARD
    0.0
  end
  return reward
end

############
#=
function code_reward{T}(code::Expr, Dl::DFSetLabeled{T})
  codelen = length(string(code))
  if codelen > MAXCODELENGTH #avoid long evaluations on long codes
    return MAX_NEG_REWARD
  end

  f = to_function(code)
  predicts = map(f, Dl.records)
  infogain, _, _ = get_metrics(predicts, Dl.labels)
  return infogain
end

function tree_reward{T}(tree::DerivationTree, Dl::DFSetLabeled{T})
  r = if iscomplete(tree) #compilable
    code = get_expr(tree)
    rew = code_reward(code, Dl)
    println("complete=", code)
    println("reward=", rew)
    rew
  elseif isterminal(tree) #not-compilable
    println("terminal=", string(get_expr(tree)))
    MAX_NEG_REWARD
  else #each step
    STEP_REWARD
  end
end
=#
#######

function script3(; seed=1,
                 data::DFSet=DATASET,
                 data_meta::DataFrame=DATASET_META)
  srand(seed)

  Dl = nmacs_vs_nonnmacs(data, data_meta)

  grammar = create_grammar()
  tree_params = DerivTreeParams(grammar, MAXSTEPS)
  tree = DerivationTree(tree_params)

  tree_reward_f = x -> tree_reward(x, Dl) #@anon doesn't return a function...
  mdp_params = DerivTreeMDPParams(grammar, tree_reward_f)

  mdp_observer = Observer()
  #add_observer(mdp_observer, "verbose1", x->println(x[1]))
  #add_observer(mdp_observer, "verbose2", x->println("  ", x[1]))

  mdp = DerivTreeMDP(mdp_params, tree, observer=mdp_observer)

  solver = MCTSSolver(n_iterations=2000, depth=40, exploration_constant=30.0)
  policy = MCTSPolicy(solver, mdp)

  initialize!(tree)
  s = create_state(mdp)
  sp = create_state(mdp)

  i = 1
  while !isterminal(tree) && i < 30
    println("step ", i)
    a = action(policy, s)
    println("action", a)
    step!(mdp, s, sp, a)
    copy!(s, sp)
    i += 1
  end
  println("final reward=", tree_reward(tree, Dl))
  println("final code=", string(get_expr(tree)))
  return tree
end
