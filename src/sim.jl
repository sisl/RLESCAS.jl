using ArgParse
using ConfParser

function parse_commandline()
  s = ArgParseSettings()

  @add_arg_table s begin
    "--file", "-f"
    help = "input config file"
    arg_type = String
    "command"
    help = "run"
    required = true
  end

  return parse_args(s)
end

#
retrieve_block(s::ConfParse, block::ASCIIString) = s._data[block]

function init_singlethreat()

  include("config/config_ACASX_EvE.jl") #defineSim
end

function init_multithreat()

  include("config/config_ACASX_Multi.jl") #defineSim
end

function init_main()
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

function main(args::Vector{UTF8String} = UTF8String[])

  if !isempty(args)
    empty!(ARGS)
    push!(ARGS, args...)
  end

  parsed_args = parse_commandline()

  command = convert(ASCIIString, parsed_args["command"])
  config_file = convert(ASCIIString, parsed_args["file"])

  conf = ConfParse(config_file)
  parse_conf!(conf)

  for (k, v) in retrieve_block(conf, "default")

    if k == "number_of_aircraft"
      if v == 2
        #single threat
        init_singlethreat()
      elseif v == 3
        #multithreat
        init_multithreat()
      elseif v > 3
        #experimental...
        init_multithreat()
      else
        error("invalid number_of_aircraft")
      end

    elseif k == "mcts_iterations"

    elseif k == "encounters"
    elseif k == "libcas"
    elseif k == "libcas_config"
    else
      warn("invalid keyword skipped: $k")
    end

  end

  init_main()

  #println(retrieve_block(conf, "simulation"))
  #println(retrieve_block(conf, "mcts"))
end

if !isempty(ARGS)
  main()
end
