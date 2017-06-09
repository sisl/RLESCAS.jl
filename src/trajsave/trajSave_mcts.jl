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

module TrajSaveMCTS

export MCTSStudy

using AdaptiveStressTesting
using SISLES: GenerativeModel

using CPUTime
using RLESUtils, Obj2Dict, RunCases, Observers, Loggers, Obj2DataFrames

using ..Config_ACASX_GM
using ..ConfigAST
using ..ConfigMCTS
using ..DefineSave
import ..DefineSave.trajSave
using ..TrajSaveCommon
using ..DefineLog
using ..SaveTypes
using ..PostProcess

type MCTSStudy
  fileroot::String
end

function MCTSStudy(;
                   fileroot::AbstractString = "trajSaveMCTS")
  MCTSStudy(fileroot)
end

function trajSave(study_params::MCTSStudy,
                  cases::Cases=Cases(Case());
                  outdir::AbstractString="./", 
                  postproc::PostProcessing=StandardPostProc())

    println("Starting MCTS Study...")
    pmap(case -> begin
        starttime_us = CPUtime_us()
        startnow = string(now())

        sim_params = defineSimParams(; extract_params(case, "sim_params")...)
        ast_params = defineASTParams(; extract_params(case, "ast_params")...)
        mcts_params = defineMCTSParams(; extract_params(case, "mcts_params")...)
        study_params = extract_params!(study_params, case, "study_params")

        sim = defineSim(sim_params)
        ast = defineAST(sim, ast_params)

        result = stress_test(ast, mcts_params)
        reward, action_seq, q_vals = result.reward, result.action_seq, result.q_values

        fileroot_ = "$(study_params.fileroot)_$(sim.string_id)"
        outfileroot = joinpath(outdir, fileroot_)
        trajLoggedPlay(ast, action_seq, study_params, sim_params, ast_params, 
            mcts_params, outfileroot)

         return reward
       end,

       cases)
end

function trajLoggedPlay(ast::AdaptiveStressTest, action_seq,
        study_params,
        sim_params,
        ast_params::ASTParams,
        mcts_params,
        outfileroot::AbstractString
        )

    #replay to get logs
    log = addObservers(ast.sim)
    replay_reward, action_seq2 = play_sequence(ast, action_seq)

    @notify_observer(sim.observer, "run_info", Any[reward, sim.md_time, sim.hmd, 
        sim.vmd, sim.label_as_nmac])
    @notify_observer(sim.observer, "action_seq", Any[action_seq])

    #sanity check replay
    @assert replay_reward == reward
    @assert action_seq2 == action_seq

    compute_info = ComputeInfo(startnow, string(now()), gethostname(), 
        (CPUtime_us() - starttime_us) / 1e6)

    #Save
    add_varlist!(log, "run_type")
    push!(log, "run_type", ["run_type", "MCTS"])
    Loggers.set!(log, "compute_info", to_df(compute_info))
    Loggers.set!(log, "study_params", to_df(study_params))
    Loggers.set!(log, "sim_params", to_df(sim_params))
    Loggers.set!(log, "ast_params", to_df(ast_params))
    Loggers.set!(log, "mcts_params", to_df(mcts_params))
    Loggers.set!(log, "q_values", q_vals)

    outfile = trajSave(outfileroot, log)

    #callback for postprocessing
    postprocess(outfile, postproc)
end

end #module
