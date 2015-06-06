using RLESMDPs
using SISLES.GenerativeModel

using CPUTime
using Dates

import Obj2Dict

function trajReplay(savefile::String)

  d = trajLoad(savefile)
  fileroot = string(getSaveFileRoot(savefile), "_replay")

  return trajReplay(d; fileroot = fileroot)
end

function trajReplay(d::SaveDict; fileroot::String = "")

  sim_params = Obj2Dict.to_obj(d["sim_params"])
  mdp_params = Obj2Dict.to_obj(d["mdp_params"])
  reward = sv_reward(d)

  sim = defineSim(sim_params)
  mdp = defineMDP(sim, mdp_params)
  action_seq = Obj2Dict.to_obj(d["sim_log"]["action_seq"])

  simLog = SimLog()
  addObservers!(simLog, mdp)

  reward = playSequence(getTransitionModel(mdp), action_seq)

  notifyObserver(sim, "run_info", Any[reward, sim.md_time, sim.hmd, sim.vmd, sim.label_as_nmac])

  #Save
  sav = d #copy original
  sav["sim_log"] = simLog #replace with new log

  replay_reward = sv_reward(d)  #there's rounding in logs, so need to compare the log version of rewards

  if replay_reward != reward
    warn("traj_save_load::trajReplay: replay reward is different than original reward")
  end

  fileroot = isempty(fileroot) ? "trajReplay$(enc)" : fileroot
  outfilename = trajSave(fileroot, sav)

  return outfilename
end
