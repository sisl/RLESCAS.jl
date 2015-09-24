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

using SISLES.GenerativeModel

using CPUTime
using Dates
using RLESUtils: Obj2Dict, RunCases

type MCBestStudy
  fileroot::String
  trial::Int64
  nsamples::Int64
  maxtime_s::Float64
end

MCBestStudy(;
       fileroot::String = "trajSaveMCBEST",
       trial::Int64 = 0,
       nsamples::Int64 = 200,
       maxtime_s::Float64 = realmax(Float64)
       ) =
  MCBestStudy(fileroot,
         trial,
         nsamples,
         maxtime_s
         )

type MCBestStudyResults
  nsamples::Int64    # actual number of samples used, i.e., when limited by time
  rewards::Vector{Float64}  #vector of all the rewards
end

MCBestStudyResults() = MCBestStudyResults(0, Float64[])

function trajSave(study_params::MCBestStudy,
                  cases::Cases = Cases(Case());
                  outdir::String = "./", postproc::Function=identity)

  pmap(case -> begin
         starttime_us = CPUtime_us()
         startnow = string(now())

         sim_params = extract_params!(defineSimParams(), case, "sim_params")
         ast_params = extract_params!(defineASTParams(), case, "ast_params")
         study_params = extract_params!(study_params, case, "study_params")

         sim = defineSim(sim_params)
         ast = defineAST(sim, ast_params)

         #generate different samples by varying the action counter initial value
         function init(i::Int)
           set_from_seed!(ast.rng, i + study_params.trial * study_params.nsamples)
           return getTransitionModel(ast), ast
         end

         rewards, action_seqs, nsamples = directSample(init, uniform_policy,
                                                       study_params.nsamples,
                                                       maxtime_s = study_params.maxtime_s)

         study_results = MCBestStudyResults(nsamples, rewards)

         besti = indmax(rewards)
         model, ast = init(besti)

         #replay to get the logs
         simLog = SimLog()
         addObservers!(simLog, ast)

         reward, action_seq = directSample(model, ast, uniform_policy)

         notifyObserver(sim, "run_info", Any[reward, sim.md_time, sim.hmd, sim.vmd, sim.label_as_nmac])

         #sanity check replay
         @assert reward == rewards[besti]
         @assert action_seq == action_seqs[besti]

         compute_info = ComputeInfo(startnow,
                                    string(now()),
                                    gethostname(),
                                    (CPUtime_us() - starttime_us) / 1e6)

         #Save
         sav = SaveDict()
         sav["run_type"] = "MCBEST"
         sav["compute_info"] = Obj2Dict.to_dict(compute_info)
         sav["study_params"] = Obj2Dict.to_dict(study_params)
         sav["study_results"] = Obj2Dict.to_dict(study_results)
         sav["sim_params"] = Obj2Dict.to_dict(ast.sim.params)
         sav["ast_params"] = Obj2Dict.to_dict(ast.params)
         sav["sim_log"] = simLog

         fileroot_ = "$(study_params.fileroot)_$(sim.string_id)"
         outfileroot = joinpath(outdir, fileroot_)
         outfile = trajSave(outfileroot, sav)

         #callback for postprocessing
         postproc(outfile)

         return reward
       end,

       cases)
end
