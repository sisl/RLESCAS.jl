using Obj2Dict

#runtype captions
function vis_runtype_caps(d::SaveDict, run_type::String)

  if run_type == "ONCE"
    cap = "Encounter. "
  elseif run_type == "MCBEST"
    cap = "Best Monte Carlo. nsamples=$(Obj2Dict.to_obj(d["study_params"]).nsamples). "
  elseif run_type == "MCTS"
    cap = "MCTS. N=$(Obj2Dict.to_obj(d["dpw_params"]).n). "
  else
    warn("vis_captions::vis_runtype_caps: No such run type! ")
    cap = ""
  end

  return cap
end

#sim parameter captions
function vis_sim_caps(d::SaveDict)

  sim_caps_helper(Obj2Dict.to_obj(d["sim_params"]))
end

function sim_caps_helper(sim_params::Union(SimpleTCAS_EvU_params, SimpleTCAS_EvE_params, ACASX_EvE_params))

  "Enc=$(sim_params.encounter_number). Cmd=$(sim_params.command_method). "
end

sim_caps_helper(sim_params::ACASX_Multi_params) = "Enc-seed=$(sim_params.encounter_seed). "

sim_caps_helper(sim_params) = ""

#runinfo captions
function vis_runinfo_caps(d::SaveDict)

  r = round(sv_reward(d), 2)
  nmac = sv_nmac(d)
  vmd = round(sv_vmd(d), 2)
  hmd = round(sv_hmd(d), 2)
  mdt = sv_md_time(d)

  return "R=$r. vmd=$vmd. hmd=$hmd. md-time=$mdt. NMAC=$nmac. "
end


# Use this when Value types become available in 0.4
##runtype captions
#vis_runtype_caps(d::SaveDict, ::Type{Val{"ONCE"}}) = "Encounter. "
#
#function vis_runtype_caps(d::SaveDict, ::Type{Val{"MCBEST"}})
#
#  "Best Monte Carlo. nsamples=$(Obj2Dict.to_obj(d["study_params"]).nsamples). "
#end
#
#vis_runtype_caps(d::SaveDict, ::Type{Val{"MCTS"}}) = "MCTS. N=$(Obj2Dict.to_obj(d["dpw_params"]).n). "
