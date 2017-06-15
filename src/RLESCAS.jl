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

module RLESCAS

export include_visualize
using Reexport

const DIR = dirname(@__FILE__)

include("config/config_ACASX_GM.jl") #defineSim
@reexport using .Config_ACASX_GM

#Config AdaptiveStressTest
include("config/config_ast.jl") #defineAST
@reexport using .ConfigAST

#Config MCTS solver
include("config/config_mcts.jl") #defineMCTS
@reexport using .ConfigMCTS

#Config MCBest solver
include("defines/mcbest.jl") #defineSim
@reexport using .MCBest
include("config/config_mcbest.jl") #defineMCBest
@reexport using .ConfigMCBest

include("defines/define_save.jl") #trajSave, trajLoad and helpers
@reexport using .DefineSave
include("defines/define_log.jl") #SimLog
@reexport using .DefineLog
include("defines/save_types.jl") #ComputeInfo
@reexport using .SaveTypes
include("helpers/save_helpers.jl")
@reexport using .SaveHelpers

include("helpers/label270.jl")
@reexport using .Label270
include("helpers/add_supplementary.jl") #add label270
@reexport using .AddSupplementary
include("tools/label270_to_text.jl")
@reexport using .Label270_To_Text
include("tools/summarize.jl")
@reexport using .Summarize
include("converters/log_to_csv.jl")
@reexport using .Log_To_CSV
include("converters/log_to_scripted.jl")
@reexport using .Log_To_Scripted
include("converters/log_to_waypoints.jl")
@reexport using .Log_To_Waypoints

include("helpers/plot_nmacs.jl")
@reexport using .PlotNMACs

include("visualize/visualize.jl")

function include_visualize()
  @eval @reexport using .Visualize 
end

include("trajsave/trajSave_common.jl")
@reexport using .TrajSaveCommon
include("helpers/fill_to_max_time.jl")
@reexport using .Fill_To_Max_Time
include("trajsave/trajSave_replay.jl")
@reexport using .TrajSaveReplay
include("trajsave/post_process.jl")
@reexport using .PostProcess
include("trajsave/trajSave_once.jl")
@reexport using .TrajSaveOnce
include("trajsave/trajSave_mcbest.jl")
@reexport using .TrajSaveMCBest
include("trajsave/trajSave_mcts.jl")
@reexport using .TrajSaveMCTS

include("tools/nmac_stats.jl")
@reexport using .NMACStats
#include("tools/json_update.jl")
#@reexport using .JsonUpdate
include("tools/recursive_plot.jl")
@reexport using .RecursivePlot
include("tools/collage.jl")
@reexport using .Collage
include("tools/sortbylikelihood.jl")
@reexport using .SortByLikelihood

end #module
