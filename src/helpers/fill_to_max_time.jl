using RLESMDPs  #For ESAction
import Obj2Dict

include("../defines/define_save.jl")

function fill_to_max_time(filename::String)
  d = trajLoad(filename)

  # disable ending on nmac
  sim_params = Obj2Dict.to_obj(d["sim_params"])
  sim_params.end_on_nmac = false
  d["sim_params"] = Obj2Dict.to_dict(sim_params)

  action_seq = Obj2Dict.to_obj(d["sim_log"]["action_seq"])

  max_steps = sim_params.max_steps
  steps_to_append = max_steps - length(action_seq)  #determine missing steps

  # steps_to_append > 0 check is automatically handled
  actions_to_append = ESAction[ ESAction(uint32(hash(t))) for t = 1 : steps_to_append ] #append hash of t
  action_seq = vcat(action_seq, actions_to_append)

  d["sim_log"]["action_seq"] = Obj2Dict.to_dict(action_seq)

  outfilename = trajSave(string(getSaveFileRoot(filename), "_filled"), d, compress = isCompressedSave(filename))

  println("File: ", filename, "; Steps appended: ", steps_to_append)

  return outfilename
end

function fill_replay(filename::String)

  fillfile = fill_to_max_time(filename)
  outfile = trajReplay(fillfile)

  rm(fillfile) #delete intermediate fill file

  return outfile
end

fill_replay{T <: String}(filenames::Vector{T}) = map(fill_replay, filenames)
