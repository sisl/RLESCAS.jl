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

module ConfigAST

export defineASTParams, defineAST

using SISLES
using SISLES.GenerativeModel
using AdaptiveStressTesting

const COST_ACCEL_NEAR_RA = -5000.0

function defineASTParams(;
                         max_steps::Int64 = 51,
                         rsg_length::Int64 = 3,
                         init_seed::Int64 = 0,
                         reset_seed::Union{Void,Int64} = nothing)
  p = ASTParams()
  p.max_steps = max_steps
  p.rsg_length = rsg_length
  p.init_seed = init_seed
  p.reset_seed = reset_seed

  return p
end

function get_reward_custom(prob::Float64, event::Bool, terminal::Bool, dist::Float64,
                            ast::AdaptiveStressTest) 
  r = log(prob)

  #penalize for maneuvering too close to RA
  pr = ast.sim.pr
  if any(pr[i].accel_near_RA for i=1:length(pr))
    r += COST_ACCEL_NEAR_RA
  end

  if event
    r += 0.0
  elseif terminal #incur distance cost only if !event && terminal
    r += -dist
  end
  return r
end

function defineAST(sim::AbstractGenerativeModel, p::ASTParams)
  return AdaptiveStressTest(p, sim, GenerativeModel.initialize, GenerativeModel.update,
                 GenerativeModel.isterminal, get_reward_custom)
end

end #module
