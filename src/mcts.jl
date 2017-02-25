# *****************************************************************************
# Written by Ritchie Lee, ritchie.lee@sv.cmu.edu
# *****************************************************************************
# Copyright ã 2015, United States Government, as represented by the
# Administrator of the National Aeronautics and Space Administration. All
# rights reserved.  The Reinforcement Learning Encounter Simulator (RLES)
# platform is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You
# may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0. Unless @everywhered by applicable
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

using Compat
import Compat: ASCIIString, UTF8String

using RLESCAS
using ConfParser
using RLESUtils, RunCases

function parseargs(args::Vector{UTF8String})
  #arg1 = config file
  if length(args) != 1
    error("wrong number of arguments.  \nCommand line usage: julia mcts.jl config.ini")
  end
  return configfile = convert(ASCIIString, args[1])
end

# the default one in the package isn't meant to return the whole block as a dict
#override
function retrieve_block(s::ConfParse, block::ASCIIString)
  haskey(s._data, block) ? s._data[block] : []
end

function check(condition::Bool, errormsg::ASCIIString="check failed")
  if !condition
    error(errormsg)
  end
end

function mcts_main()
  configfile = parseargs(ARGS)
  conf = ConfParse(configfile)
  parse_conf!(conf)

  number_of_aircraft = -1
  encounter_ranges = nothing
  config = Dict{ASCIIString,Vector{Any}}()
  output_filters = ASCIIString[]
  outputs = ASCIIString[]
  output_dir = "./"
  quiet = false

  #Process default block
  for (k, v) in retrieve_block(conf, "default")
    #Obj2Dict doesn't work well with UTF8String and substring
    #work exclusively in ASCIIString
    v = convert(Array{ASCIIString}, v)
    if k == "number_of_aircraft"
      check(length(v) == 1, "config: number_of_aircraft: invalid number of parameters ($(length(v)))")
      config["sim_params.num_aircraft"] = [parse(Int,v[1])]
    elseif k == "encounter_equipage"
      check(length(v) == 1)
      config["sim_params.encounter_equipage"] = [Symbol(v[1])]
    elseif k == "encounter_model"
      check(length(v) == 1)
      config["sim_params.encounter_model"] = [Symbol(v[1])]
    elseif k == "response_model"
      check(length(v) == 1)
      config["sim_params.response_model"] = [Symbol(v[1])]
    elseif k == "cas_model"
      check(length(v) == 1)
      config["sim_params.cas_model"] = [Symbol(v[1])]
    elseif k == "dynamics_model"
      check(length(v) == 1)
      config["sim_params.dynamics_model"] = [Symbol(v[1])]
    elseif k == "encounters"
      check(length(v) >= 1, "config: encounters: invalid number of parameters ($(length(v)))")
      encounters = parse_ranges(v)
      config["sim_params.encounter_number"] = encounters
    elseif k == "encounter_file"
      check(length(v) == 1, "config: encounter_file: invalid number of parameters ($(length(v)))")
      encounter_file = abspath(v[1])
      config["sim_params.encounter_file"] = [encounter_file]
    elseif k == "initial"
      check(length(v) == 1, "config: initial: invalid number of parameters ($(length(v)))")
      initial = abspath(v[1])
      config["sim_params.initial_sample_file"] = [initial]
    elseif k == "transition"
      check(length(v) == 1, "config: transition: invalid number of parameters ($(length(v)))")
      transition = abspath(v[1])
      config["sim_params.transition_sample_file"] = [transition]
    elseif k == "mcts_iterations"
      check(length(v) == 1, "config: mcts_iterations: invalid number of parameters ($(length(v)))")
      mcts_iterations = parse(Int,v[1])
      config["mcts_params.n"] = [mcts_iterations]
    elseif k == "libcas"
      check(length(v) == 1, "config: libcas: invalid number of parameters ($(length(v)))")
      libcas = abspath(v[1])
      config["sim_params.libcas"] = [libcas]
    elseif k == "libcas_config"
      check(length(v) == 1, "config: libcas_config: invalid number of parameters ($(length(v)))")
      libcas_config = abspath(v[1])
      config["sim_params.libcas_config"] = [libcas_config]
    elseif k == "output_dir"
      check(length(v) == 1, "config: output_dir: invalid number of parameters ($(length(v)))")
      output_dir = abspath(v[1])
    elseif k == "output_filters"
      filters = map(x -> convert(ASCIIString, x), v)
      output_filters = vcat(output_filters, filters)
    elseif k == "outputs"
      outs = map(x -> convert(ASCIIString, x), v)
      outputs = vcat(outputs, outs)
    elseif k == "quiet"
      check(length(v) == 1, "config: quiet: invalid number of parameters ($(length(v)))")
      quiet = bool(v[1]) #TODO(Ritchie): implement this
    else
      warn("invalid keyword skipped: $k")
    end
  end

  map_block!(config, conf, "simulation", "sim_params") # Process simulation block
  map_block!(config, conf, "ast", "ast_params") # Process ast block
  map_block!(config, conf, "mcts", "mcts_params") # Process mcts block
  map_block!(config, conf, "study", "study_params") # Process study block
  map_block!(config, conf, "manual", "", separator = "") #don't prefix, directly apply, # Process manual block

  # Create the final config
  cases = generate_cases(collect(config)...)
  config_seeds!(cases) #seed each encounter with a different init_seed

  return rewards = trajSave(MCTSStudy(), cases, postproc=StandardPostProc(outputs, output_filters),
                            outdir=output_dir)
end

function parse_ranges(ranges::Vector{ASCIIString})
  #Only supports int ranges delimited by -, : or ,
  #e.g., 1-5,7-10,12
  out = Int[]
  for subexpr in ranges
    s = split(subexpr, ['-', ':'])
    if length(s) == 1
      push!(out, parse(Int,s[1]))
    elseif length(s) == 2
      r = parse(Int,s[1]):parse(Int,s[2])
      out = vcat(out, r)
    else
      error("parse_ranges: invalid range expression")
    end
  end
  return out
end

function map_block!(config::Dict{ASCIIString,Vector{Any}}, conf::ConfParse,
                    from_block::ASCIIString, to_param::ASCIIString; separator::ASCIIString=".")
  for (k, v) in retrieve_block(conf, from_block)
    composite_key = string(to_param, separator, k)
    config[composite_key] = v
  end
end

#vary the encounter seed and init seed with the encounter number
function config_seeds!(cases::Cases)
  add_field!(cases, "ast_params.init_seed", x -> Int64(x), ["sim_params.encounter_number"])
  add_field!(cases, "sim_params.encounter_seed", x -> UInt64(x), ["sim_params.encounter_number"])
  return cases
end

mcts_main()
