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

#Pick a scenario:
include("config/config_ACASX_EvE.jl") #defineSim
#include("config/config_ACASX_Multi.jl") #defineSim

#Config AdaptiveStressTest
include("config/config_ast.jl") #defineAST

#Config MCTS solver
include("config/config_mcts.jl") #defineMCTS

include("defines/define_log.jl") #SimLog
include("defines/define_save.jl") #trajSave, trajLoad and helpers
include("defines/save_types.jl") #ComputeInfo
include("helpers/save_helpers.jl")

include("visualize/visualize.jl") #pgfplotLog

include("trajsave/trajSave_common.jl")
include("trajsave/trajSave_once.jl")
include("trajsave/trajSave_mcbest.jl")
include("trajsave/trajSave_mcts.jl")
include("trajsave/trajSave_replay.jl")

include("helpers/add_supplementary.jl") #add label270
include("tools/label270_to_text.jl")
include("tools/summarize.jl")
include("converters/json_to_csv.jl")
include("converters/json_to_scripted.jl")
include("converters/json_to_waypoints.jl")

include("helpers/fill_to_max_time.jl")

include("tools/nmac_stats.jl")
