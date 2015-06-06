include("D3Vis/D3_MCTSvis.jl")

function d3vis_save(enc::Int; limit_steps::Union(Int64,Nothing)=nothing)
  sim = defineSim(enc,:DBN)
  mdp = defineMDP(sim)
  dpw = defineMCTS(mdp)

  if limit_steps != nothing
    dpw.f.model.maxSteps = limit_steps
  end

  step = 1
  function selectActionwPlot(dpw::DPW,s::State; verbose::Bool=false)
    action = selectAction(dpw,s)

    outfile = "sim$enc-$step.json"
    saveSimTree(dpw,s,outfile)

    step += 1

    return action
  end

  mcts_reward,action_seq = simulate(dpw.f.model,dpw,selectActionwPlot,verbose=true)

end
