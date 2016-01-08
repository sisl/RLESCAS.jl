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

module DerivTreeMDPs

using Reexport
@reexport using DerivationTrees
using RLESUtils.Observers
using POMDPs
using GrammaticalEvolution
using Iterators

export DerivTreeMDPParams, DerivTreeState, DerivTreeAction, DerivTreeMDP, DerivTreeStateSpace, DerivTreeActionSpace
export DerivTreeTransitionDistr, discount, n_actions, actions, domain, reward, sync!, step!
export create_state, create_action, create_transition_distribution

import DerivationTrees.step!
import Base: ==, hash, rand!, copy!, push!

type DerivTreeMDPParams
  grammar::Grammar
  reward::Function #r = reward(tree::DerivationTree)
  discount::Float64
end
DerivTreeMDPParams(grammar::Grammar, reward_fn::Function) = DerivTreeMDPParams(grammar, reward_fn, 1.0)

type DerivTreeState <: State #make sure this is deepcopyable
  past_actions::Vector{Int64} #actions taken since initialize!
end
DerivTreeState() = DerivTreeState(Int64[])

type DerivTreeAction <: Action
  action_id::Int64
end
DerivTreeAction() = DerivTreeAction(-1)

type DerivTreeMDP <: POMDP
  params::DerivTreeMDPParams
  tree::DerivationTree #true state of the sim
  current_state::DerivTreeState #for syncing purposes
  all_actions::Vector{DerivTreeAction}
  observer::Observer
end

function DerivTreeMDP(p::DerivTreeMDPParams, tree::DerivationTree; observer::Observer=Observer())
  all_actions = generate_all_actions(p.grammar)
  return DerivTreeMDP(p, tree, DerivTreeState(), all_actions, observer)
end

type DerivTreeStateSpace <: AbstractSpace
  mdp::DerivTreeMDP
  action_id::Int64
end

type DerivTreeActionSpace <: AbstractSpace
  mdp::DerivTreeMDP
  action_ids::Vector{Int64}
end

type DerivTreeTransitionDistr <: AbstractDistribution
  mdp::DerivTreeMDP
  current_state::DerivTreeState
  action::DerivTreeAction
end

DerivTreeTransitionDistr(mdp) = DerivTreeTransitionDistr(mdp, DerivTreeState(), DerivTreeAction())

function generate_all_actions(grammar::Grammar)
  return [DerivTreeAction(i) for i = 1:maxlength(grammar)]
end

# returns the discount factor
POMDPs.discount(mdp::DerivTreeMDP) = mdp.params.discount

# returns the nubmer of actions in the problem
function POMDPs.n_actions(mdp::DerivTreeMDP, s::DerivTreeState)
  @notify_observer(mdp.observer, "verbose2", ["n_actions called"])
  #check that mdp is in sync with state
  sync!(mdp, s)
  return length(actionspace(mdp.tree))
end

#add to POMDPs.jl
#fallback when needed
#function actions(mdp::DerivTreeMDP, s::State, as::AbstractSpace; fallback::Bool=true)
#  return fallback ? actions(mdp) : error("actions and fallback not defined")
#end

# returns the action space for the entire problem
POMDPs.actions(mdp::DerivTreeMDP) = DerivTreeActionSpace(mdp, collect(1:length(mdp.all_actions)))

# fills the action space with the actions availiable from state s
using Debug
function POMDPs.actions(mdp::DerivTreeMDP, s::DerivTreeState, as::DerivTreeActionSpace)
  @notify_observer(mdp.observer, "verbose2", ["actions called"])
  #check that mdp is in sync with state
  sync!(mdp, s)
  as.action_ids = collect(actionspace(mdp.tree)) #reachable actions
  return as
end

function POMDPs.domain(action_space::DerivTreeActionSpace)
  @notify_observer(action_space.mdp.observer, "verbose2", ["domain called"])
  all_actions = action_space.mdp.all_actions
  ids = action_space.action_ids
  return imap(id -> all_actions[id], ids) #iterator avoids allocation
end

# fills d with neighboring states reachable from the s,a pair
function POMDPs.transition(mdp::DerivTreeMDP, s::DerivTreeState, a::DerivTreeAction, d::DerivTreeTransitionDistr)
  @notify_observer(mdp.observer, "verbose2", ["transition called"])
  #check that mdp is in sync with state
  sync!(mdp, s)
  #what's needed for the rand! call
  d.mdp = mdp
  copy!(d.current_state, s)
  d.action = a
  return d
end

# fills sp with random sample from distribution d
function POMDPs.rand!(rng::AbstractRNG, sp::DerivTreeState, d::DerivTreeTransitionDistr)
  return step!(d.mdp, d.current_state, sp, d.action)
end

function step!(mdp::DerivTreeMDP, s::DerivTreeState, sp::DerivTreeState, a::DerivTreeAction)
  @notify_observer(mdp.observer, "verbose1", ["mdp step! called"])
  #check that mdp is in sync with state
  sync!(mdp, s)
  step!(mdp.tree, a.action_id) #deterministic transition
  copy!(sp, s)
  push!(sp, a)
  copy!(mdp.current_state, sp) #update sync obj
  return sp
end

# returns the immediate reward of being in state s and performing action a
POMDPs.reward(mdp::DerivTreeMDP, s::DerivTreeState, a::DerivTreeAction) = reward(mdp, s)

function POMDPs.reward(mdp::DerivTreeMDP, s::DerivTreeState)
  @notify_observer(mdp.observer, "verbose2", ["reward called"])
  #check that mdp is in sync with state
  sync!(mdp, s)
  return mdp.params.reward(mdp.tree)
end

# returns a boolean indicating if state s is terminal
function POMDPs.isterminal(mdp::DerivTreeMDP, s::DerivTreeState)
  @notify_observer(mdp.observer, "verbose2", ["isterminal called"])
  #check that mdp is in sync with state
  sync!(mdp, s)
  return DerivationTrees.isterminal(mdp.tree)
end

# initializes a model state
POMDPs.create_state(mdp::DerivTreeMDP) = DerivTreeState()

# initializes a model action
POMDPs.create_action(mdp::DerivTreeMDP) = DerivTreeAction()

# initializes a distirbution over states
POMDPs.create_transition_distribution(mdp::DerivTreeMDP) = DerivTreeTransitionDistr(mdp)

# if you want to use a random policy you need to implement an action space sampling function
# fills action a with a random action form action_space
function POMDPs.rand!(rng::AbstractRNG, a::DerivTreeAction, action_space::DerivTreeActionSpace)
  a.action_id = rand(rng, action_space.action_ids)
  return a
end

#equate all fields
function ==(s1::DerivTreeState, s2::DerivTreeState)
  s1.past_actions == s2.past_actions
end

#hash all fields
function hash(s::DerivTreeState)
  h = hash(DerivTreeState)
  for a in s.past_actions
    h = hash(h, UInt64(a))
  end
  return h
end

function sync!(mdp::DerivTreeMDP, s::DerivTreeState)
  @notify_observer(mdp.observer, "verbose2", ["sync! called current=$(mdp.current_state.past_actions), s=$(s.past_actions)"])
  #if sync'd, we're done
  mdp.current_state == s && return
  @notify_observer(mdp.observer, "verbose1", ["sync'ing"])
  #resync
  initialize!(mdp.tree)
  reset!(mdp.current_state)
  for a in s.past_actions
    step!(mdp.tree, a)
  end
end

reset!(s::DerivTreeState) = empty!(s.past_actions)

function copy!(dst::DerivTreeState, src::DerivTreeState)
  resize!(dst.past_actions, length(src.past_actions))
  copy!(dst.past_actions, src.past_actions)
  return dst
end

push!(s::DerivTreeState, a::DerivTreeAction) = push!(s.past_actions, a.action_id)

end #module
