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

module DescriptionMap

export DESCRIP_MAP

function get_map(num_aircraft::Int64 = 2)
  D = Dict{ASCIIString,ASCIIString}()
  for i = 1:num_aircraft
    D["RA_$i"] = "active RA on aircraft $i"
    D["vert_rate_$i"] = "aircraft $i's vertical rate "
    D["alt_diff_$i"] = "altitude difference relative to aircraft $i"
    D["psi_$i"] = "aircraft $i's heading angle"
    D["intr_sr_$i"] = "aircraft $i's intruder slant range"
    D["intr_chi_$i"] = "aircraft $i's intruder bearing"
    D["intr_vrc0_$i"] = "aircraft $i's input vrc bit 0 is set"
    D["intr_vrc1_$i"] = "aircraft $i's input vrc bit 1 is set"
    D["intr_vrc2_$i"] = "aircraft $i's input vrc bit 2 is set"
    D["cc0_$i"] = "aircraft $i's cc bit 0 is set"
    D["cc1_$i"] = "aircraft $i's cc bit 1 is set"
    D["cc2_$i"] = "aircraft $i's cc bit 2 is set"
    D["vc0_$i"] = "aircraft $i's vc bit 0 is set"
    D["vc1_$i"] = "aircraft $i's vc bit 1 is set"
    D["vc2_$i"] = "aircraft $i's vc bit 2 is set"
    D["ua0_$i"] = "aircraft $i's ua bit 0 is set"
    D["ua1_$i"] = "aircraft $i's ua bit 1 is set"
    D["ua2_$i"] = "aircraft $i's ua bit 2 is set"
    D["da0_$i"] = "aircraft $i's da bit 0 is set"
    D["da1_$i"] = "aircraft $i's da bit 1 is set"
    D["da2_$i"] = "aircraft $i's da bit 2 is set"
    D["target_rate_$i"] = "aircraft $i's RA target rate"
    D["crossing_$i"] = "crossing RA is issued to aircraft $i"
    D["alarm_$i"] = "RA alarm occurs on aircraft $i"
    D["alert_$i"] = "RA alert occurs aircraft $i"
    D["intr_out_vrc0_$i"] = "aircraft $i's output vrc bit 0 is set"
    D["intr_out_vrc1_$i"] = "aircraft $i's output vrc bit 1 is set"
    D["intr_out_vrc2_$i"] = "aircraft $i's output vrc bit 2 is set"
    D["intr_out_tds_$i"] = "aircraft $i's output tds"
    D["response_none_$i"] = "pilot $i is flying intended trajectory"
    D["response_stay_$i"] = "pilot $i is responding to previous RA"
    D["response_follow_$i"] = "pilot $i is responding to current RA"
    D["response_timer_$i"] = "number of seconds remaining in pilot $i's response delay"
    D["response_h_d_$i"] = "pilot $i's commanded vertical rate"
    D["response_psi_d_$i"] = "pilot $i's commanded turn rate"
    D["v_$i"] = "aircraft $i's velocity"
    D["h_$i"] = "aircraft $i's altitude"
  end
  D["converging"] = "aircraft are converging"
  return D
end

const DESCRIP_MAP = get_map()

end #module

