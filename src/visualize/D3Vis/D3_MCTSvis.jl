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

using JSON

push!(LOAD_PATH,joinpath(pwd(),"/../"))
using MDP
import MCTSdpw: DPW, State, Action, StateNode, StateActionNode, StateActionStateNode

function saveSimTree(dpw::DPW,s::State,outfile::AbstractString)

  function process(sn::StateNode,Tout)
    for (a,san) in sn.a
      node_ = Dict{ASCIIString, Any}()
      node_["action"] = hash(a)
      node_["N"] = san.n
      node_["Q"] = san.q
      node_["states"] = Dict{ASCIIString, Any}[]

      push!(Tout, node_)

      process(san, node_["states"])
    end
  end

  function process(san::StateActionNode, Tout)
    for (s, sasn) in san.s
      node_ = Dict{ASCIIString, Any}()
      node_["state"] = hash(s)
      node_["N"] = haskey(dpw.s,s) ? dpw.s[s].n : sasn.n
      node_["r"] = sasn.r
      node_["actions"] = Dict{ASCIIString, Any}[]

      push!(Tout, node_)

      if haskey(dpw.s,s)
        process(dpw.s[s], node_["actions"])
      end
    end
  end

  function process{S<:State}(ss::Vector{S}, Tout)
    for s in ss
      node_ = Dict{ASCIIString, Any}()
      node_["state"] = hash(s)
      node_["N"] = dpw.s[s].n
      node_["actions"] = Dict{ASCIIString, Any}[]

      push!(Tout, node_)

      if haskey(dpw.s,s)
        process(dpw.s[s], node_["actions"])
      end
    end
  end

  Tout = Dict{ASCIIString, Any}()
  Tout["name"] = "root"
  Tout["states"] = Dict{ASCIIString, Any}[]

  process([s],Tout["states"])
  f = open(outfile, "w")
  JSON.print(f, Tout, 2)
  close(f)

  return Tout
end
