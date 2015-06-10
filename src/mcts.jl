using ConfParser
using RunCases

function parseargs(args::Vector{UTF8String})
  #arg1 = config file
  #

  if length(args) != 1
    error("wrong number of arguments.  \nCommand line usage: julia mcts.jl config.ini")
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
    require(Pkg.dir("RLESCAS", "src", "config/config_ACASX_EvE.jl")) #defineSim
  elseif number_of_aircraft == 3
    require(Pkg.dir("RLESCAS", "src", "config/config_ACASX_Multi.jl")) #defineSim
  else
    error("invalid number_of_aircraft")
  end

  #Pick a reward function:
  require(Pkg.dir("RLESCAS", "src", "defines/define_reward.jl")) #get_reward #supports ACASX_EvE and ACASX_Multi

  #Config RLESMDP
  require(Pkg.dir("RLESCAS", "src", "config/config_mdp.jl")) #defineMDP

  #Config MCTS solver
  require(Pkg.dir("RLESCAS", "src", "config/config_mcts.jl")) #defineMCTS

  # TODO: where do these methods go?
  require(Pkg.dir("RLESCAS", "src", "trajsave/traj_sim.jl")) #directSample,runMcBest,runMCTS

  require(Pkg.dir("RLESCAS", "src", "defines/define_log.jl")) #SimLog
  require(Pkg.dir("RLESCAS", "src", "defines/define_save.jl")) #trajSave, trajLoad and helpers
  require(Pkg.dir("RLESCAS", "src", "defines/save_types.jl")) #ComputeInfo
  require(Pkg.dir("RLESCAS", "src", "helpers/save_helpers.jl"))

  require(Pkg.dir("RLESCAS", "src", "trajsave/trajSave_common.jl"))
  require(Pkg.dir("RLESCAS", "src", "trajsave/trajSave_once.jl"))
  require(Pkg.dir("RLESCAS", "src", "trajsave/trajSave_mcbest.jl"))
  require(Pkg.dir("RLESCAS", "src", "trajsave/trajSave_mcts.jl"))
  require(Pkg.dir("RLESCAS", "src", "trajsave/trajSave_replay.jl"))

  require(Pkg.dir("RLESCAS", "src", "helpers/add_supplementary.jl")) #add label270
  require(Pkg.dir("RLESCAS", "src", "helpers/fill_to_max_time.jl"))

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

    #Obj2Dict doesn't work well with UTF8String and and substring
    #work exclusively in ASCIIString
    v = convert(Array{ASCIIString}, v)

    if k == "number_of_aircraft"

      check(length(v) == 1, "config: number_of_aircraft: invalid number of parameters ($(length(v)))")
      number_of_aircraft = int(v[1])
      init(number_of_aircraft)

    elseif k == "encounters"

      check(length(v) >= 1, "config: encounters: invalid number of parameters ($(length(v)))")
      encounter_ranges = v

    elseif k == "initial"

      check(length(v) == 1, "config: initial: invalid number of parameters ($(length(v)))")
      initial = v[1]
      config["sim_params.initial_sample_file"] = [initial]

    elseif k == "transition"

      check(length(v) == 1, "config: transition: invalid number of parameters ($(length(v)))")
      transition = v[1]
      config["sim_params.transition_sample_file"] = [transition]

    elseif k == "mcts_iterations"

      check(length(v) == 1, "config: mcts_iterations: invalid number of parameters ($(length(v)))")
      mcts_iterations = int(v[1])
      config["mcts_params.n"] = [mcts_iterations]

    elseif k == "libcas"

      check(length(v) == 1, "config: libcas: invalid number of parameters ($(length(v)))")
      libcas = v[1]
      config["sim_params.libcas"] = [libcas]

    elseif k == "libcas_config"

      check(length(v) == 1, "config: libcas_config: invalid number of parameters ($(length(v)))")
      libcas_config = string(v[1])
      config["sim_params.libcas_config"] = [libcas_config]

    elseif k == "output_dir"

      check(length(v) == 1, "config: output_dir: invalid number of parameters ($(length(v)))")
      output_dir = v[1]

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

    #fill and add supplementary to all files
    fill_replay(filename, overwrite=true)
    add_supplementary(filename)

    #filters
    for f in output_filters

      if f == "nmacs_only" && !nmacs_only(filename)
        return #if it fails any of the filters, we're done
      end
    end

    #outputs
    sort!(outputs)
    #sorting prevents pdf from appearing after tex.  This works around tex being deleted as
    #an intermediate file during the pdf process

    for o in outputs

      if o == "pdf"
        include(Pkg.dir("RLESCAS", "src", "visualize/visualize.jl"))
        trajPlot(filename, format="PDF")
      elseif o == "tex"
        include(Pkg.dir("RLESCAS", "src", "visualize/visualize.jl"))
        trajPlot(filename, format="TEX")"tr"
      elseif o == "scripted"
        include(Pkg.dir("RLESCAS", "src", "converters/json_to_scripted.jl"))
        json_to_scripted(filename)
      elseif o == "waypoints"
        include(Pkg.dir("RLESCAS", "src", "converters/json_to_waypoints.jl"))
        json_to_waypoints(filename)
      elseif o == "csv"
        include(Pkg.dir("RLESCAS", "src", "converters/json_to_csv.jl"))
        json_to_csv(filename)
      elseif o == "label270_text"
        include(Pkg.dir("RLESCAS", "src", "tools/label270_to_text.jl"))
        label270_to_text(filename)
      elseif o == "summary"
        include(Pkg.dir("RLESCAS", "src", "tools/summarize.jl"))
        summarize(filename)
      else
        warn("config: unrecognized output")
      end

    end

  end

  rewards = trajSave(MCTSStudy(), cases, postproc=postproc, outdir=output_dir)

  return rewards
end

function parse_ranges(ranges::Vector{ASCIIString})
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

function map_block!(config::Dict{ASCIIString,Vector{Any}}, conf::ConfParse,
                    from_block::ASCIIString, to_param::ASCIIString; separator::ASCIIString=".")

  for (k, v) in retrieve_block(conf, from_block)

    composite_key = string(to_param, separator, k)
    config[composite_key] = v
  end

end

function config_encounters!(config::Dict{ASCIIString,Vector{Any}}, number_of_aircraft::Int, encounter_ranges::Vector{ASCIIString})

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
