include("../helpers/TikzUtils.jl")
include("../helpers/save_helpers.jl")

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

function irs_vis(files::Vector{String}; outfileroot::String="irs_vis")

  #attributes defined by callbacks
  #[encounter number, iterations, total reward, isnmac]
  callbacks = [x -> sv_encounter_id(x)[1], sv_dpw_iterations, sv_reward, sv_nmac]

  #encounter files (rows) x attributes (cols)
  data = Array(Any, length(files), length(callbacks))

  for (row, file) in enumerate(files)
    d = trajLoad(file)
    data[row, :] = map(f -> f(d), callbacks)
  end

  td = TikzDocument()
  plotArray = Plots.Plot[]

  for enc in unique(data[:, 1])
    rows = find(x -> x[1] == enc, data[:, 1])
    sort!(rows, by=r -> data[r, 2])
    xs = convert(Vector{Float64}, data[rows, 2])
    ys = convert(Vector{Float64}, data[rows, 3])

    push!(plotArray,Plots.Linear(xs, ys, legendentry = "Encounter $(enc)"))
  end

  tp = PGFPlots.plot(Axis(plotArray,
                          xlabel = "MCTS Iterations",
                          ylabel = "Total Reward",
                          title = "MCTS DPW Iterations vs. Total Reward",
                          legendPos = "south east"))

  cap = "MCTS DPW Iterations vs. Total Reward"

  add_to_document!(td, tp, cap)

  outfile = string(outfileroot, ".pdf")
  TikzPictures.save(PDF(outfile), td)
  outfile = string(outfileroot, ".tex")
  TikzPictures.save(TEX(outfile), td)

end

