include("../defines/define_save.jl")
include("../helpers/save_helpers.jl")

function summarize(filename::String; ndecimals::Int=2)
  d = trajLoad(filename)

  outfilename = string(getSaveFileRoot(filename), "_summary.txt")
  f = open(outfilename, "w")

  println(f, "encounter = $(sv_encounter_id(d)[1])")
  println(f, "number of aircraft = $(sv_num_aircraft(d))")
  println(f, "run type = $(sv_run_type(d))")
  println(f, "nmac = $(sv_nmac(d))")
  println(f, "reward = $(round(sv_reward(d), ndecimals))")
  println(f, "hmd = $(round(sv_hmd(d), ndecimals))")
  println(f, "vmd = $(round(sv_vmd(d), ndecimals))")
  println(f, "md_time = $(sv_md_time(d))")
  println(f, "logProbs = $(sv_simlog_tdata_vid(d,"logProb","logProb"))")

  close(f)

  return outfilename
end
