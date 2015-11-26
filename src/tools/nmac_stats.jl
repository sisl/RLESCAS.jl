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

include("../helpers/save_helpers.jl")

const NMAC_STATS_ROUND_NDECIMALS = 2

function nmac_stats{T<:AbstractString}(infiles::Vector{T}, txtfile::AbstractString = "nmac_stats.txt")

  stats = Dict{ASCIIString,Any}()

  for file = infiles

    d = trajLoad(file)
    run_type = d["run_type"]

    if !haskey(stats, run_type)
      stats[run_type] = Dict{ASCIIString,Any}()
      stats[run_type]["nmac_count"] = Int64(0)
      stats[run_type]["nmac_encs_rewards"] = (Int64, Float64)[]
      stats[run_type]["total_count"] = Int64(0)
    end

    @show file

    if sv_nmac(d) #nmac occurred

      #increment count
      stats[run_type]["nmac_count"] += 1

      enc_id, enctype = sv_encounter_id(d)

      #add encounter to list
      if enctype != "invalid"
        push!(stats[run_type]["nmac_encs_rewards"],
              (enc_id, sv_reward(d)))
      else
        error("nmac_stats: Invalid encounter id")
      end
    end

    #increment total_count
    stats[run_type]["total_count"] += 1
  end

  #open file
  f = open(txtfile, "w")

  #sort the vectors
  for run_type = keys(stats)

    enc_rewards = stats[run_type]["nmac_encs_rewards"]
    sort!(enc_rewards, by = x -> x[2], rev = true)
    sorted_ids = [tup[1] for tup in enc_rewards]
    sorted_rewards = [tup[2] for tup in enc_rewards]

    if isopen(f)
      println(f, "run type=$run_type")
      println(f, "nmac count=$(stats[run_type]["nmac_count"])")
      println(f, "total count=$(stats[run_type]["total_count"])")
      println(f, "sorted nmac ids=$(sorted_ids)")
      println(f, "sorted nmac rewards=$(round(sorted_rewards, NMAC_STATS_ROUND_NDECIMALS))")
      println(f, "")
    end

  end

  close(f)

  return stats
end
