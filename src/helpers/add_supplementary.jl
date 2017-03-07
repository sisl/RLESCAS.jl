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

module AddSupplementary

export add_label270, add_supplementary

using ..DefineSave
using ..SaveHelpers
using ..Label270

add_label270{T<:AbstractString}(files::Vector{T}) = map(add_label270, files)
function add_label270(file::AbstractString)
  d = trajLoad(file)
  ra_names = sv_simlog_names(d, "ra")

  b_label_exists = any(x -> x == "label270", ra_names)
  b_label_short_exists = any(x -> x == "label270_short", ra_names)

  if b_label_exists && b_label_short_exists
    return #already processed, nothing to do
  end

  #append field to var_names
  if !b_label_exists
    push!(d["sim_log"]["var_names"]["ra"], "label270")
    push!(d["sim_log"]["var_units"]["ra"], "text")
  end

  if !b_label_short_exists
    push!(d["sim_log"]["var_names"]["ra"], "label270_short")
    push!(d["sim_log"]["var_units"]["ra"], "text")
  end

  cr_index = findfirst(x -> x == "crossing", ra_names)
  cc_index = findfirst(x -> x == "cc", ra_names)
  vc_index = findfirst(x -> x == "vc", ra_names)
  ua_index = findfirst(x -> x == "ua", ra_names)
  da_index = findfirst(x -> x == "da", ra_names)

  if any(x -> x == 0, [cr_index, cc_index, vc_index, ua_index, da_index])
    error("add_supplementary: Flags not found!")
  end

  ra_top = d["sim_log"]["ra"]
  num_aircraft = length(ra_top["aircraft"])

  for i = 1:num_aircraft
    ra_i = ra_top["aircraft"][string(i)]
    t_end = length(ra_i["time"])
    prev_label_code = 0 #code at previous change
    code_tm1 = 0 #code at t-1

    for t = 1:t_end
      ra = ra_i["time"][string(t)]
      code = get_code(ra[cc_index], ra[vc_index], ra[ua_index], ra[da_index])
      crossing = ra[cr_index]
      #prev_code is previous different code
      if code != code_tm1
        prev_label_code = code_tm1
      end
      if !b_label_exists
        label = get_textual_label(code, prev_label_code, crossing, true)
        push!(ra, label) #append to data vector
      end
      if !b_label_short_exists
        label_short = get_textual_label(code, prev_label_code, crossing, false)
        push!(ra, label_short) #append to data vector
      end
      code_tm1 = code
    end
  end
  trajSave(getSaveFileRoot(file), d, compress=isCompressedSave(file))
end

add_supplementary{T<:AbstractString}(files::Vector{T}) = map(add_supplementary, files)
function add_supplementary(file::AbstractString)
  add_label270(file)
end

end #module
