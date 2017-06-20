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
using DataFrames

using ..Config_ACASX_GM
using ..ConfigAST
using ..ConfigMCTS
using ..DefineSave
using ..TrajSaveCommon
using ..DefineLog
using ..SaveTypes
using ..SaveHelpers
using ..PostProcess

import ..DefineSave.trajSave
import ..TrajSaveCommon.get_study_params

type MCTSStudy
    fileroot::String
end

function MCTSStudy(;
    fileroot::AbstractString="trajSaveMCTS")
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

        results = stress_test2(ast, mcts_params)

        compute_info = ComputeInfo(startnow, string(now()), gethostname(), 
            (CPUtime_us() - starttime_us) / 1e6)

        save_k_logs(sim, mcts_params, ast, results, compute_info, 
            sim_params, ast_params, study_params, postproc, outdir)

        results.rewards[1]
    end, cases)

end

function get_study_params(d::TrajLog, ::Type{Val{:MCTS}})
    study = MCTSStudy()
    Obj2DataFrames.set!(study, ObjDataFrame(d["study_params"]))
end

function save_k_logs(sim::Any, mcts_params::DPWParams, ast::AdaptiveStressTest, 
    results::StressTestResults, compute_info::ComputeInfo, sim_params, 
    ast_params::ASTParams, study_params::MCTSStudy, postproc::PostProcessing, 
    outdir::AbstractString)
    for k = 1:mcts_params.top_k
        fileroot_ = "$(study_params.fileroot)_$(sim.string_id)_k$k"
        outfileroot = joinpath(outdir, fileroot_)
        save_mcts_log(mcts_params, ast, results, k, compute_info, sim_params,
            ast_params, study_params, postproc, outfileroot)
    end
end

function save_k_logs(sim::DualSim, mcts_params::DPWParams, ast::AdaptiveStressTest, 
    results::StressTestResults, compute_info::ComputeInfo, sim_params, 
    ast_params::ASTParams, study_params::MCTSStudy, postproc::PostProcessing, 
    outdir::AbstractString)
    #save
    ds_transition_model = ast.transition_model
    ds_sim = ast.sim

    #sim1
    ast.sim = ds_sim.sim1
    ast.transition_model = transition_model(ast)
    for k = 1:mcts_params.top_k
        fileroot_ = "$(study_params.fileroot)_$(ast.sim.string_id)_k$(k)_sim1"
        outfileroot = joinpath(outdir, fileroot_)
        save_mcts_log(mcts_params, ast, results, k, compute_info, sim_params[1],
            ast_params, study_params, postproc, outfileroot; suppress_warn=true)
    end

    #sim2
    ast.sim = ds_sim.sim2
    ast.transition_model = transition_model(ast)
    for k = 1:mcts_params.top_k
        fileroot_ = "$(study_params.fileroot)_$(ast.sim.string_id)_k$(k)_sim2"
        outfileroot = joinpath(outdir, fileroot_)
        save_mcts_log(mcts_params, ast, results, k, compute_info, sim_params[2],
            ast_params, study_params, postproc, outfileroot; suppress_warn=true)
    end

    #restore
    ast.sim = ds_sim
    ast.transition_model = ds_transition_model

    ast
end

function save_mcts_log(mcts_params::DPWParams, ast::AdaptiveStressTest, 
    results::StressTestResults, k::Int64, compute_info::ComputeInfo,
    sim_params, ast_params::ASTParams, study_params::MCTSStudy, postproc, 
    outfileroot::AbstractString; suppress_warn::Bool=false)

    log = trajLoggedPlay(ast, results.rewards[k], results.action_seqs[k], 
        compute_info, sim_params, ast_params; suppress_warn=suppress_warn)

    set_run_type!(log, "MCTS")
    set_mcts_params!(log, mcts_params)
    set_q_values!(log, results.q_values[k])
    set_study_params!(log, study_params)
    set_action_seq!(log, results.action_seqs[k])
    set_q_values!(log, results.q_values[k])

    outfile = trajSave(outfileroot, log)

    #callback for postprocessing
    postprocess(outfile, postproc)
end

end #module
