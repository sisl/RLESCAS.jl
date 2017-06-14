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

module TrajSaveReplay

export trajReplay, fill_replay

using AdaptiveStressTesting
using RLESUtils, Obj2Dict, Observers
using CPUTime

using ..Config_ACASX_GM
using ..ConfigAST
using ..ConfigMCTS
using ..DefineSave
using ..SaveHelpers
using ..TrajSaveCommon
using ..Fill_To_Max_Time
using ..DefineLog
using ..SaveTypes

function trajReplay(savefile::AbstractString; fileroot::AbstractString="")
    d = trajLoad(savefile)
    if isempty(fileroot)
        fileroot = string(getSaveFileRoot(savefile), "_replay")
    end
    trajReplay(d; fileroot=fileroot)
end

function trajReplay(d::TrajLog; fileroot::AbstractString="")
    sim_params = get_sim_params(d)
    ast_params = get_ast_params(d)
    reward = get_reward(d)
    action_seq = get_action_seq(d)

    sim = defineSim(sim_params)
    ast = defineAST(sim, ast_params)
    compute_info = get_compute_info(d)
    study_params = get_study_params(d)

    d2 = trajLoggedPlay(ast, reward, action_seq, compute_info, sim_params, ast_params)

    copy!(d, d2)
    outfile = trajSave(fileroot, d)

    outfile
end

function fill_replay(filename::AbstractString; overwrite::Bool=false)
    fillfile = fill_to_max_time(filename)
    if overwrite
        outfile = trajReplay(fillfile, fileroot=getSaveFileRoot(filename))
    else
        outfile = trajReplay(fillfile)
    end
    rm(fillfile) #delete intermediate fill file
    outfile
end

fill_replay{T<:AbstractString}(filenames::Vector{T}) = map(fill_replay, filenames)

end #module
