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

using SISLES
using SISLES.WorldModel
using SISLES.GenerativeModel
using SISLES.PilotResponse
import ACASX_Common

const NMAC_REWARD = 0.0
const RESPONSE_FILTER_THRESH = 8 #seconds #TODO: save this somewhere in log file

function get_reward(sim::Union(ACASX_EvE, ACASX_Multi))
  reward = sim.step_logProb
  if ACASX_Common.isterminal(sim)
    if ACASX_Common.NMAC_occurred(sim) && response_filter(sim.pr, RESPONSE_FILTER_THRESH)
      reward += NMAC_REWARD
      sim.label_as_nmac = true
    else
      reward += -sim.md
      sim.label_as_nmac = false
    end
  end
  return reward
end

#returns true if at least 1 aircraft responds within response_thresh seconds
response_filter(pr::Vector, resp_thresh) = any(map(p -> response_filter_(p, resp_thresh), pr))
response_filter_(pr::StochasticLinearPR, resp_thres::Int64) = pr.response_time <= resp_thresh
function response_filter_(pr::LLDetPR, resp_thresh::Int64)
  return pr.initial_resp_time <= resp_thresh && pr.subsequent_resp_time <= resp_thresh
end
