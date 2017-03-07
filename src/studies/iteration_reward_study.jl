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

include("../helpers/TikzUtils.jl")
include("../helpers/save_helpers.jl")

using RunCases
using Obj2Dict

using TikzPictures
import PGFPlots: Plots,Axis

function irs_2ac_mcts_script(encounter::Int64, iterations::Vector{Int64})
  #for 1 encounter

  cases = generate_cases(("sim_params.encounter_number",
                          [encounter]),
                         ("mcts_params.maxtime_s",
                          [realmax(Float64)]),
                         ("mcts_params.n",
                          iterations))

  add_field!(cases, "study_params.fileroot", n -> "trajSaveMCTS_enc$(encounter)_n$(n)",
             ["mcts_params.n"])

  trajSave(MCTSStudy(), cases)

end

function irs_vis{T<:AbstractString}(files::Vector{T}; outfileroot::AbstractString="irs_vis")

  #attributes defined by callbacks
  #[encounter number, iterations, total reward, isnmac]
  callbacks = [x -> sv_encounter_id(x)[1], sv_dpw_iterations, sv_reward, sv_nmac]

  #encounter files (rows) x attributes (cols)
  data = Array(Any, length(files), length(callbacks))

  for (row, file) in enumerate(files)
    d = trajLoad(file)
    data[row, :] = map(f -> f(d), callbacks)
  end

  td = TikzDocument()
  plotArray = Plots.Plot[]

  for enc in unique(data[:, 1])
    rows = find(x -> x[1] == enc, data[:, 1])
    sort!(rows, by=r -> data[r, 2])
    xs = convert(Vector{Float64}, data[rows, 2])
    ys = convert(Vector{Float64}, data[rows, 3])

    push!(plotArray,Plots.Linear(xs, ys, legendentry = "Encounter $(enc)"))
  end

  tp = PGFPlots.plot(Axis(plotArray,
                          xlabel = "MCTS Iterations",
                          ylabel = "Total Reward",
                          title = "MCTS DPW Iterations vs. Total Reward",
                          legendPos = "south east"))

  cap = "MCTS DPW Iterations vs. Total Reward"

  add_to_document!(td, tp, cap)

  outfile = string(outfileroot, ".pdf")
  TikzPictures.save(PDF(outfile), td)
  outfile = string(outfileroot, ".tex")
  TikzPictures.save(TEX(outfile), td)

end

