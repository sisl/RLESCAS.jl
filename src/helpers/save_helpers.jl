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

module SaveHelpers

using ..Config_ACASX_GM, ..ConfigAST, ..ConfigMCTS, ..ConfigMCBest
using ..DefineSave
using ..SaveTypes
using RLESUtils, DataFrameUtils, Obj2DataFrames, Loggers, RNGWrapper
using DataFrames
using AdaptiveStressTesting

export set_sim_params!, set_ast_params!, set_mcts_params!, set_compute_info!,
    set_study_params!, set_run_type!, set_q_values!, set_action_seq!, set_result!,
    set_mcbest_params!, set_study_results!
export get_sim_params, get_ast_params, get_mcts_params, get_compute_info, get_result, 
    get_action_seq, get_study_params, get_mcbest_params, get_study_results
export get_reward, get_num_aircraft, get_vmd, get_hmd, get_md_time, get_nmac, is_nmac,
    nmacs_only

set_sim_params!(d::TrajLog, sim_params) = Loggers.set!(d.log, "sim_params", to_df(sim_params))
set_ast_params!(d::TrajLog, ast_params) = Loggers.set!(d.log, "ast_params", to_df(ast_params))
set_mcts_params!(d::TrajLog, mcts_params) = Loggers.set!(d.log, "mcts_params", to_df(mcts_params))
set_mcbest_params!(d::TrajLog, mcbest_params) = Loggers.set!(d.log, "mcbest_params", 
    to_df(mcbest_params))
set_compute_info!(d::TrajLog, compute_info) = Loggers.set!(d.log, "compute_info", 
    to_df(compute_info))
set_study_params!(d::TrajLog, study_params) = Loggers.set!(d.log, "study_params", 
    to_df(study_params))
set_study_results!(d::TrajLog, study_results) = Loggers.set!(d.log, "study_results", 
    to_df(study_results))
set_run_type!(d::TrajLog, run_type) = Loggers.set!(d.log, "run_type", 
    DataFrame(Dict(:run_type=>[run_type])))
set_q_values!(d::TrajLog, q_vals) = Loggers.set!(d.log, "q_values",
    DataFrame(Dict(:q_values=>q_vals)))

function set_result!(d::TrajLog, result) 
    #reward is saved under run_info
    set_action_seq!(d, result.action_seq)
    set_q_values!(d, result.q_values)
end

function set_action_seq!(d::TrajLog, action_seq) 
    n = length(action_seq[1].rsg)
    df = DataFrame(fill(UInt32, n), 0)
    for a in action_seq
        push!(df, a.rsg.state)
    end
    Loggers.set!(d.log, "action_seq", df)
end

get_sim_params(d::TrajLog) = Obj2DataFrames.set!(defineSimParams(), ObjDataFrame(d["sim_params"]))
get_ast_params(d::TrajLog) = Obj2DataFrames.set!(defineASTParams(), ObjDataFrame(d["ast_params"]))
get_mcts_params(d::TrajLog) = Obj2DataFrames.set!(defineMCTSParams(), 
    ObjDataFrame(d["mcts_params"]))
get_mcbest_params(d::TrajLog) = Obj2DataFrames.set!(defineMCBestParams(), 
    ObjDataFrame(d["mcbest_params"]))
get_compute_info(d::TrajLog) = Obj2DataFrames.set!(ComputeInfo(),    
    ObjDataFrame(d["compute_info"]))
function get_action_seq(d::TrajLog) 
    x = ASTAction[]
    df = d["action_seq"]
    n = ncol(df)
    for row in eachrow(df)
        A = squeeze(convert(Array, row), 1)
        push!(x, ASTAction(RSG(A)))
    end
    x
end
get_run_type(d::TrajLog) = d.log["run_type"][1, :run_type]
get_q_values(d::TrajLog) = d.log["q_values"][:q_values]
get_study_params(d::TrajLog) = get_study_params(d, Val{Symbol(get_run_type(d))})
get_study_results(d::TrajLog) = get_study_results(d, Val{Symbol(get_run_type(d))})
function get_result(d::TrajLog) 
    reward = get_reward(d)
    action_seq = get_action_seq(d)
    q_values = get_q_values(d)
    StressTestResults(reward, action_seq, q_values)
end

get_reward(d::TrajLog) = d.log["run_info"][1, :reward] 
get_num_aircraft(d::TrajLog) = d.log["sim_params"][1, :num_aircraft]
get_vmd(d::TrajLog) = d.log["run_info"][1, :vmd]
get_hmd(d::TrajLog) = d.log["run_info"][1, :hmd]
get_md_time(d::TrajLog) = d.log["run_info"][1, :md_time]

is_nmac(file::AbstractString) = file |> trajLoad |> get_nmac
get_nmac(d::TrajLog) = d.log["run_info"][1, :nmac] 
nmacs_only(file::AbstractString) = is_nmac(file)
nmacs_only{T<:AbstractString}(files::Vector{T}) = filter(is_nmac, files)

end #module
