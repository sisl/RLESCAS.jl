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

module VisCaptions

export vis_runtype_caps, vis_sim_caps, vis_runinfo_caps

using RLESUtils, Obj2Dict
using SISLES.GenerativeModel

using ...DefineSave
using ...SaveHelpers

#runtype captions
function vis_runtype_caps(d::TrajLog)
    typ = run_type(d)
    if typ == "ONCE"
        cap = "Encounter. "
    elseif typ == "MCBest"
        cap = "MC. N=$(get_mcbest_n(d)). "
    elseif typ == "MCTS"
        cap = "MCTS. N=$(get_mcts_iterations(d)). "
    else
        warn("vis_captions::vis_runtype_caps: No such run type! ")
        cap = ""
    end
    cap
end

#sim parameter captions.  TODO: make this more robust
function vis_sim_caps(d::TrajLog)
    #ACASX_GM...for now
    return "" 
end

#runinfo captions
function vis_runinfo_caps(d::TrajLog)
  r = round(get_reward(d), 2)
  nmac = get_nmac(d)
  vmd = round(get_vmd(d), 2)
  hmd = round(get_hmd(d), 2)
  mdt = get_md_time(d)
  return "R=$r. vmd=$vmd. hmd=$hmd. md-time=$mdt. NMAC=$nmac. "
end

end #module
