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

using RLESUtils.Obj2Dict
using SISLES.GenerativeModel

#runtype captions
function vis_runtype_caps(d::SaveDict, run_type::String)
  if run_type == "ONCE"
    cap = "Encounter. "
  elseif run_type == "MCBEST"
    cap = "Best Monte Carlo. nsamples=$(Obj2Dict.to_obj(d["study_params"]).nsamples). "
  elseif run_type == "MCTS"
    cap = "MCTS. N=$(sv_mcts_iterations(d)). "
  else
    warn("vis_captions::vis_runtype_caps: No such run type! ")
    cap = ""
  end
  return cap
end

#sim parameter captions.  TODO: make this more robust
function vis_sim_caps(d::SaveDict)
  if d["sim_params"]["type"] == "SimpleTCAS_EvU_params" ||
    d["sim_params"]["type"] == "SimpleTCAS_EvE_params" ||
    d["sim_params"]["type"] == "ACASX_EvE_params"
    return "Enc=$(sv_encounter_id(d)[1]). Cmd=$(sv_command_method(d)). "
  elseif d["sim_params"]["type"] == "ACASX_Multi_params"
    return "Enc-seed=$(sv_encounter_id(d)). "
  else
    return ""
  end
end

#runinfo captions
function vis_runinfo_caps(d::SaveDict)
  r = round(sv_reward(d), 2)
  nmac = sv_nmac(d)
  vmd = round(sv_vmd(d), 2)
  hmd = round(sv_hmd(d), 2)
  mdt = sv_md_time(d)
  return "R=$r. vmd=$vmd. hmd=$hmd. md-time=$mdt. NMAC=$nmac. "
end


# Use this when Value types become available in 0.4
##runtype captions
#vis_runtype_caps(d::SaveDict, ::Type{Val{"ONCE"}}) = "Encounter. "
#
#function vis_runtype_caps(d::SaveDict, ::Type{Val{"MCBEST"}})
#
#  "Best Monte Carlo. nsamples=$(Obj2Dict.to_obj(d["study_params"]).nsamples). "
#end
#
#vis_runtype_caps(d::SaveDict, ::Type{Val{"MCTS"}}) = "MCTS. N=$(Obj2Dict.to_obj(d["mcts_params"]).n). "
