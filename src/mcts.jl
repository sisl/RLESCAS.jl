using ConfParser
using RunCases

function parseargs(args::Vector{UTF8String})
  #arg1 = config file
  #

  if length(args) != 1
    #TODO: Print usage:
    error("wrong number of arguments")
  end

  configfile = convert(ASCIIString, args[1])

  return configfile
end

# the default one isn't meant to return the whole block as a dict
function retrieve_block(s::ConfParse, block::ASCIIString)
  haskey(s._data, block) ? s._data[block] : []
end

function init(number_of_aircraft::Int)

  if number_of_aircraft == 2
    include("config/config_ACASX_EvE.jl") #defineSim
  elseif number_of_aircraft == 3
    include("config/config_ACASX_Multi.jl") #defineSim
  else
    error("invalid number_of_aircraft")
  end

  #Pick a reward function:
  include("defines/define_reward.jl") #get_reward #supports ACASX_EvE and ACASX_Multi

  #Config RLESMDP
  include("config/config_mdp.jl") #defineMDP

  #Config MCTS solver
  include("config/config_mcts.jl") #defineMCTS

  # TODO: where do these methods go?
  include("trajsave/traj_sim.jl") #directSample,runMcBest,runMCTS

  include("defines/define_log.jl") #SimLog
  include("defines/define_save.jl") #trajSave, trajLoad and helpers
  include("defines/save_types.jl") #ComputeInfo
  include("helpers/save_helpers.jl")

  include("trajsave/trajSave_common.jl")
  include("trajsave/trajSave_once.jl")
  include("trajsave/trajSave_mcbest.jl")
  include("trajsave/trajSave_mcts.jl")
  include("trajsave/trajSave_replay.jl")

  include("helpers/add_supplementary.jl") #add label270
  include("helpers/fill_to_max_time.jl")
end

function check(condition::Bool, errormsg::String="check failed")

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
  config = Dict{String,Vector{Any}}()
  output_filters = String[]
  outputs = String[]

  #Process default block
  for (k, v) in retrieve_block(conf, "default")

    if k == "number_of_aircraft"

      check(length(v) == 1, "config: number_of_aircraft: invalid number of parameters ($(length(v)))")
      number_of_aircraft = int(v[1])
      init(number_of_aircraft)

    elseif k == "mcts_iterations"

      check(length(v) == 1, "config: mcts_iterations: invalid number of parameters ($(length(v)))")
      mcts_iterations = int(v[1])
      config["mcts_params.n"] = [mcts_iterations]

    elseif k == "encounters"

      check(length(v) >= 1, "config: encounters: invalid number of parameters ($(length(v)))")
      encounter_ranges = v

    elseif k == "libcas"

      check(length(v) == 1, "config: libcas: invalid number of parameters ($(length(v)))")
      libcas = string(v[1])
      config["sim_params.libcas"] = [libcas]

    elseif k == "libcas_config"

      check(length(v) == 1, "config: libcas_config: invalid number of parameters ($(length(v)))")
      libcas_config = string(v[1])
      config["sim_params.libcas_config"] = [libcas_config]

    elseif k == "output_filters"

      filters = map(x -> convert(ASCIIString, x), v)
      output_filters = vcat(output_filters, filters)

    elseif k == "outputs"

      outs = map(x -> convert(ASCIIString, x), v)
      outputs = vcat(outputs, outs)

    else
      warn("invalid keyword skipped: $k")
    end

  end

  # Process simulation block
  map_block!(config, conf, "simulation", "sim_params")

  # Process mdp block
  map_block!(config, conf, "mdp", "mdp_params")

  # Process mcts block
  map_block!(config, conf, "mcts", "mcts_params")

  # Process study block
  map_block!(config, conf, "study", "study_params")

  # Process manual block
  map_block!(config, conf, "manual", "", separator = "") #don't prefix, directly apply

  # Create the final config
  config_encounters!(config, number_of_aircraft, encounter_ranges)

  cases = generate_cases(collect(config)...)

  function postproc(filename::String)

    println("postprocess me")
    #output_filters
    #outputs

  end

  trajSave(MCTSStudy(), cases, postproc=postproc)

end

function parse_ranges(ranges::Vector{String})
  #Only supports int ranges delimited by -, : or ,
  #i.e., 1-5,7-10,12

  out = Int[]
  for subexpr in ranges
    s = split(subexpr, ['-', ':'])
    if length(s) == 1
      push!(out, int(s[1]))
    elseif length(s) == 2
      r = int(s[1]):int(s[2])
      out = vcat(out, r)
    else
      error("parse_ranges: invalid range expression")
    end
  end

  return out
end

function map_block!(config::Dict{String,Vector{Any}}, conf::ConfParse,
                    from_block::String, to_param::String; separator::String=".")

  for (k, v) in retrieve_block(conf, from_block)

    composite_key = string(to_param, separator, k)
    config[composite_key] = v
  end

end

function config_encounters!(config::Dict{String,Vector{Any}}, number_of_aircraft::Int, encounter_ranges::Vector{String})

  encounters = parse_ranges(encounter_ranges)

  if number_of_aircraft == 2
    config["sim_params.encounter_number"] = [encounters]
  elseif number_of_aircraft == 3
    config["sim_params.encounter_seed"] = [encounters]
  elseif number_of_aircraft == -1
    error("number_of_aircraft must be declared in config file")
  else
    error("invalid number_of_aircraft in config file")
  end
end

mcts_main()
