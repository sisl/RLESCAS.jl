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

module TrajSaveCommon

export extract_params!, extract_params, trajLoggedPlay

using AdaptiveStressTesting
using CPUTime
using RLESUtils, Obj2Dict, RunCases, Observers, Loggers, Obj2DataFrames
using DataFrames

using ..DefineSave
using ..SaveTypes
using ..DefineLog
using ..SaveHelpers

function extract_params!(paramObj, case::Case, key::AbstractString)
  #assumes format of key is: "key.field"

  for (k, v) in case
    k_ = split(k, '.')

    if length(k_) < 2
      warn("extract_params!::dot separator not found in $k")
    end

    if k_[1] == key
      if isdefined(paramObj, Symbol(k_[2]))
        setfield!(paramObj, Symbol(k_[2]), v)
      else
        warn("$(k_[2]) is not a member of type $(typeof(paramObj))")
      end
    end
  end

  return paramObj
end

function extract_params(case::Case, key::AbstractString)
    kwargs = Tuple{Symbol,Any}[]
    for (k, v) in case
        toks = split(k, '.')
        if length(toks) < 2
            warn("extract_params::dot separator not found in $k")
        end
        if toks[1] == key
            push!(kwargs, (toks[2], v))
        end
    end
    kwargs
end

"""
Replay trajectory instrumented with logs
"""
function trajLoggedPlay(ast::AdaptiveStressTest, reward, action_seq,
        compute_info,
        sim_params,
        ast_params::ASTParams; 
        suppress_warn::Bool=false
        )

    sim = ast.sim

    #replay to get logs
    log = addObservers(ast.sim)
    replay_reward, action_seq2 = play_sequence(ast, action_seq)

    @notify_observer(sim.observer, "run_info", Any[replay_reward, sim.md_time, sim.hmd, 
        sim.vmd, sim.label_as_nmac])

    #sanity check replay
    @assert action_seq2 == action_seq
    if !suppress_warn && !isapprox(replay_reward, reward)
        warn("trajLoggedPlay: replay reward is different than original reward. replay_reward=$(replay_reward) and reward=$reward")
    end

    #Save
    set_compute_info!(log, compute_info)
    set_sim_params!(log, sim_params)
    set_ast_params!(log, ast_params)
    set_action_seq!(log, action_seq)

    log
end

end #module
