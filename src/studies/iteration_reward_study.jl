include("../helpers/TikzUtils.jl")

using RunCases
using Obj2Dict

using TikzPictures
import PGFPlots: Plots,Axis

function irs_2ac_mcts_script(encounter::Int64, iterations::Vector{Int64})
  #for 1 encounter

  cases = generate_cases(("sim_params.encounter_number",
                          [encounter]),
                         ("mcts_params.maxtime_s",
                          [realmax(Float64)]),
                         ("mcts_params.n",
                          iterations))

  add_field!(cases, "study_params.fileroot", n -> "trajSaveMCTS_enc$(encounter)_n$(n)",
             ["mcts_params.n"])

  trajSave(MCTSStudy(), cases)

end

#=
function irs_vis(files::Vector{String}; outfileroot::String = "irs_vis", format::String = "TEXPDF")

  td = TikzDocument()

  ## This part for compute_time vs reward overlay
  d = groupattributes(files, sv_run_type, gettime, sv_reward)

  names = collect(keys(d))
  times = Vector{Float64}[]
  means = Vector{Float64}[]
  sems = Vector{Float64}[]
  ntrials = Int64[]

  for (runtype, xyvecs) in d

    #xyvecs is [(x,[y...])...]
    #t = x[1]
    #rewards = x[2]

    push!(times, map(x -> x[1], xyvecs))
    push!(means, map(x -> mean(x[2]), xyvecs))
    push!(sems, map(x -> std(x[2]) / sqrt(length(x[2])), xyvecs))

    lengths = map(x -> length(x[2]), xyvecs)
    push!(ntrials, int(median(lengths)))

  end

  pgfplotcts_reward!(td, names, times, means, sems, ntrials)

  ## This part for compute_time vs number of nmacs overlay
  d = groupattributes(files, sv_run_type, gettime, sv_nmac)

  names = collect(keys(d))
  empty!(times)
  nmacs = Vector{Float64}[]
  empty!(ntrials)

  for (runtype, xyvecs) in d

    #xyvecs is [(x,[y...])...]
    #t = x[1]
    #nmac = x[2]

    push!(times, map(x -> x[1], xyvecs))
    push!(nmacs, map(x -> sum(x[2]), xyvecs))

    lengths = map(x -> length(x[2]), xyvecs)
    push!(ntrials, int(median(lengths)))

  end
  pgfplotcts_nmacs!(td, names, times, nmacs, ntrials)

  if format == "TEXPDF"
    outfile = string(outfileroot, ".pdf")
    TikzPictures.save(PDF(outfile), td)
    outfile = string(outfileroot, ".tex")
    TikzPictures.save(TEX(outfile), td)
  elseif format == "PDF"
    outfile = string(outfileroot, ".pdf")
    TikzPictures.save(PDF(outfile), td)
  elseif format == "TEX"
    outfile = string(outfileroot, ".tex")
    TikzPictures.save(TEX(outfile), td)
  else
    warn("cts_vis::Format keyword not recognized. Only these are valid: PDF, TEX, or TEXPDF.")
  end

  return
end

function gettime(d::SaveDict)

  runtype = sv_run_type(d)

  if runtype == "MCTS"
    sim_params = Obj2Dict.to_obj(d["sim_params"])
    dpw_params = Obj2Dict.to_obj(d["dpw_params"])
    t = dpw_params.maxtime_s * sim_params.max_steps #since maxtime for mctsdpw is per step
  elseif runtype == "MCBEST"
    p = Obj2Dict.to_obj(d["study_params"])
    t = p.maxtime_s
  else
    error("gettime::No such run type $(runtype)")
  end

  return t
end

#iteration vs total reward
function irs_plotreward!(td::TikzDocument,
                            names::Vector{String},
                            times::Array{Vector{Float64}, 1},
                            means::Array{Vector{Float64}, 1},
                            sems::Array{Vector{Float64}, 1},
                            ntrials::Vector{Int64})

  plotArray = Plots.Plot[]

  n = length(times)
  for i = 1:length(times)
    push!(plotArray, Plots.ErrorBars(times[i], means[i], sems[i],
                                    #style="mark options={color=blue}",
                                    #mark="*",
                                    legendentry = "$(names[i])"))
  end

  tp = PGFPlots.plot(Axis(plotArray,
                          xlabel="Computation Time (s)",
                          ylabel="Reward",
                          title="Reward vs. Computation Time",
                          legendPos="south east"))

  cap = string("Reward vs. Computation Time Study. ntrials=$(ntrials[1]).") #TODO: make this more robust

  add_to_document!(td, tp, cap)

end

#iteration vs number of nmacs
function irs_plotnmacs!(td::TikzDocument,
                           names::Vector{String},
                           times::Array{Vector{Float64}, 1},
                           nmacs::Array{Vector{Float64}, 1},
                           ntrials::Vector{Int64})

  plotArray = Plots.Plot[]

  n = length(times)
  for i = 1:length(times)
    push!(plotArray,Plots.Linear(times[i], nmacs[i],
                                 #style="mark options={color=blue}",
                                 #mark="*",
                                 legendentry = "$(names[i])"))
  end

  tp = PGFPlots.plot(Axis(plotArray,
                          xlabel = "Computation Time (s)",
                          ylabel = "NMAC Count",
                          title = "NMAC Count vs. Computation Time",
                          legendPos = "north west"))

  cap = string("NMAC Count vs. Computation Time Study. ntrials=$(ntrials[1]).") #TODO: make this more robust

  add_to_document!(td, tp, cap)

end
=#
