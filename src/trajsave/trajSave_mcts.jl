using RLESMDPs
using SISLES.GenerativeModel

using CPUTime
using Dates
import Obj2Dict
using RunCases

type MCTSStudy
  fileroot::String
end

MCTSStudy(;
        fileroot::String = "trajSaveMCTS"
        ) =
  MCTSStudy(fileroot
          )

function trajSave(study_params::MCTSStudy,
                  runcases::Vector{RunCase} = RunCase[RunCase()];
                  outdir::String = "./")

  pmap(case -> begin
         starttime_us = CPUtime_us()
         startnow = string(now())

         sim_params = extract_params!(defineSimParams(), case, "sim_params")
         mdp_params = extract_params!(defineMDPParams(), case, "mdp_params")
         mcts_params = extract_params!(defineMCTSParams(), case, "mcts_params")
         study_params = extract_params!(study_params, case, "study_params")

         sim = defineSim(sim_params)
         mdp = defineMDP(sim, mdp_params)
         dpw = defineMCTS(mdp, mcts_params)

         reward, action_seq = runMCTS(dpw)

         #replay to get logs
         simLog = SimLog()
         addObservers!(simLog, mdp)
         replay_reward = playSequence(getTransitionModel(mdp), action_seq)

         notifyObserver(sim, "run_info", Any[reward, sim.md_time, sim.hmd, sim.vmd, sim.label_as_nmac])

         #sanity check replay
         @test replay_reward == reward

         compute_info = ComputeInfo(startnow,
                                    string(now()),
                                    gethostname(),
                                    (CPUtime_us() - starttime_us) / 1e6)

         #Save
         sav = SaveDict()
         sav["run_type"] = "MCTS"
         sav["compute_info"] = Obj2Dict.to_dict(compute_info)
         sav["sim_params"] = Obj2Dict.to_dict(sim.params)
         sav["mdp_params"] = Obj2Dict.to_dict(mdp.params)
         sav["dpw_params"] = Obj2Dict.to_dict(dpw.p)
         sav["sim_log"] = simLog

         fileroot_ = "$(study_params.fileroot)_$(sim.string_id)"
         trajSave(joinpath(outdir, fileroot_), sav)

         return reward
       end,

       runcases)
end
