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

using DerivationTrees
using POMDPs

import Base: ==, hash

type DerivTreeMDPParams
  discount::Float64
end

type DerivTreeState <: State
  past_actions::Vector{Int64} #actions taken since initialize!
  nstep::Int64 #number of times step! has been called
end
DerivTreeState() = DerivTreeState(Int64[], 0)

type DerivTreeAction <: Action
  action::Int64
end
DerivTreeAction() = DerivTreeAction(-1)

type DerivTreeMDP <: POMDP
  params::DerivTreeMDPParams
  tree::DerivationTree
end

function DerivTreeMDP(p::DerivTreeParams)
  return DerivTreeMDP()
end

type DerivTreeStateSpace <: AbstractSpace

end

type DerivTreeActionSpace <: AbstractSpace
  actions::Vector{Int64}
end

type DerivTreeTransitionDistr <: AbstractDistribution
  mdp::DerivTreeMDP
  action::Int64
end

get_actions(action_space::DerivTreeActionSpace) = action_space.actions
set_actions!(action_space::DerivTreeActionSpace, actions::Vector{Int64}) = action_space.actions = actions

# returns the discount factor
discount(mdp::DerivTreeMDP) = mdp.params.discount

# returns the nubmer of actions in the problem
n_actions(mdp::DerivTreeMDP) = length(actionspace(mdp.tree))

# returns the action space
actions(mdp::DerivTreeMDP) = DerivTreeActionSpace(collect(1:maxlength(grammar))) #entire actionspace

# fills the action space with the actions availiable from state s
function actions(mdp::DerivTreeMDP, s::State, as::ActionSpace)
  #check that mdp is in sync with state
  @assert mdp.current_state == s
  set_actions!(as.vals, collect(actionspace(mdp.tree))) #reachable action space
end

function domain(action_space::DerivTreeActionSpace)
  return imap(DerivTreeAction, get_actions(action_space))
end

# fills d with neighboring states reachable from the s,a pair
function transition(mdp::DerivTreeMDP, s::State, a::Action, d::AbstractDistribution)
  #check that mdp is in sync with state
  @assert mdp.current_state == s
  d.mdp = mdp
  d.action = a.action
end

# fills s with random sample from distribution d
function rand!(rng::AbstractRNG, s::State, d::AbstractDistribution)
  #check that mdp is in sync with state
  @assert d.mdp.current_state == s
  step!(d.mdp.tree, d.action) #deterministic transition
end

# returns the immediate reward of being in state s and performing action a
function reward(mdp::DerivTreeMDP, s::State, a::Action)
  #check that mdp is in sync with state
  @assert mdp.current_state == s
  return p.reward(mdp.tree)
end

# returns a boolean indicating if state s is terminal
function isterminal(mdp::DerivTreeMDP, s::State)
  #check that mdp is in sync with state
  @assert mdp.current_state == s
  return isterminal(mdp.tree)
end

# initializes a model state
create_state(mdp::DerivTreeMDP) = DerivTreeState()

# initializes a model action
create_action(mdp::DerivTreeMDP) = DerivTreeAction()

# initializes a distirbution over states
create_transition_distribution(mdp::DerivTreeMDP) = DerivTreeTransitionDistr()

# if you want to use a random policy you need to implement an action space sampling function
# fills action a with a random action form action_space
function rand!(rng::AbstractRNG, a::Action, action_space::AbstractSpace)
  a.action = rand(rng, get_actions(action_space))
end

#equate all fields
function ==(s1::DerivTreeState, s2::DerivTreeState)
  s1.past_actions == s2.past_actions
  s1.nstep == s2.nstep
end

#hash all fields
function hash(s::DerivTreeState)
  h = reduce(hash, map(UInt64, s.past_actions))
  h = hash(h, UInt64(s.nstep))
  return h
end

end #module
