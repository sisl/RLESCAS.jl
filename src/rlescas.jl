#Pick a scenario:
include("config/config_ACASX_EvE.jl") #defineSim
#include("config/config_ACASX_Multi.jl") #defineSim

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

include("visualize/visualize.jl") #pgfplotLog

include("trajsave/trajSave_common.jl")
include("trajsave/trajSave_once.jl")
include("trajsave/trajSave_mcbest.jl")
include("trajsave/trajSave_mcts.jl")
include("trajsave/trajSave_replay.jl")

include("helpers/add_supplementary.jl") #add label270
include("tools/label270_to_txtfile.jl")
include("converters/json_to_csv.jl")
include("converters/json_to_scripts.jl")
include("converters/json_to_waypoints.jl")

include("helpers/fill_to_max_time.jl")

include("tools/nmac_stats.jl")
