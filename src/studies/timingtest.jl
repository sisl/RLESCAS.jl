include("../rlescas.jl")


function print_results(results)
  println("\n")
  println("Function \t\t Wall Time (seconds)")
  println("============================================")
  for r = 1:size(results, 1)
    println(results[r, 1], " \t\t ", results[r, 2] )
  end
  println("\n")

end


function test_sim()
  res = Array(Any, 7, 2)

  p = defineSimParams()
  sim = defineSim(p)
  initialize(sim)
  step(sim)
  step(sim)

  #test 1
  tic();
  sim = defineSim(p)
  res[1, :] = ["defineSim(p)", toq()]

  #test 2
  tic();
  initialize(sim)
  res[2, :] = ["1st init(sim)", toq()]

  #test 3
  tic();
  step(sim)
  res[3, :] = ["1st step1(sim)", toq()]

  #test 4
  tic();
  step(sim)
  res[4, :] = ["1st step2(sim)", toq()]

  #test 5
  tic();
  initialize(sim)
  res[5, :] = ["2nd init(sim)", toq()]

  #test 6
  tic();
  step(sim)
  res[6, :] = ["2nd step1(sim)", toq()]

  #test 7
  tic();
  step(sim)
  res[7, :] = ["2nd step2(sim)", toq()]

  return res
end

function test_simcomponents()
  res = Array(Any, 10, 2)

  p = defineSimParams()
  sim = defineSim(p)
  initialize(sim)
  step(sim)
  step(sim)

  sim = defineSim(p)
  initialize(sim)

  #test 1
  tic();
  EncounterDBN.step(sim.em)
  res[1, :] = ["1st step(em)", toq()]

  states = WorldModel.getAll(sim.wm)
  command = EncounterDBN.get(sim.em, 1)

  #test 2
  tic();
  output = Sensor.step(sim.sr[1], states)
  res[2, :] = ["1st step(sr)", toq()]

  #test 3
  tic();
  RA = CollisionAvoidanceSystem.step(sim.cas[1], output)
  res[3, :] = ["1st step(cas)", toq()]

  #test 4
  tic();
  response = PilotResponse.step(sim.pr[1], command, RA)
  res[4, :] = ["1st step(pr)", toq()]

  #test 5
  tic();
  state = DynamicModel.step(sim.dm[1], response)
  res[5, :] = ["1st step(dm)", toq()]

  #test 6
  tic();
  EncounterDBN.step(sim.em)
  res[6, :] = ["2nd step(em)", toq()]

  states = WorldModel.getAll(sim.wm)
  command = EncounterDBN.get(sim.em, 1)

  #test 7
  tic();
  output = Sensor.step(sim.sr[1], states)
  res[7, :] = ["2nd step(sr)", toq()]

  #test 8
  tic();
  RA = CollisionAvoidanceSystem.step(sim.cas[1], output)
  res[8, :] = ["2nd step(cas)", toq()]

  #test 9
  tic();
  response = PilotResponse.step(sim.pr[1], command, RA)
  res[9, :] = ["2nd step(pr)", toq()]

  #test 10
  tic();
  state = DynamicModel.step(sim.dm[1], response)
  res[10, :] = ["2nd step(dm)", toq()]


  return res
end

function test_rollout()
  res = Array(Any, 3, 2)

  p = defineSimParams()
  sim = defineSim(p)
  initialize(sim)
  step(sim)
  step(sim)

  #test1 single
  tic();
  initialize(sim)
  for t = 1:50
    step(sim)
  end
  res[1, :] = ["rollout1", toq()]

  #test2 rollout
  tic();
  initialize(sim)
  for i = 1:10
    for t = 1:50
      step(sim)
    end
  end
  res[2, :] = ["rollout10", toq()]

  #test3 rollout
  tic();
  initialize(sim)
  for i = 1:100
    for t = 1:50
      step(sim)
    end
  end
  res[3, :] = ["rollout100", toq()]

  return res
end

function est_runtime(results::Array{Any, 2}, iterations::Int, nsteps::Int=50)
  init_time = results[5, 2]
  step1 = results[6, 2]
  step2 = results[7, 2]

  runtime = (init_time + step1 + (nsteps - 1) * step2) * iterations * nsteps
  println("estimated runtime: $runtime seconds or $(runtime/3600.0) hours")

  return runtime
end

function test_main()

  #[test name, wall time (seconds)]
  results = Array(Any, 0, 2)

  #test sim
  res = test_sim()
  results = vcat(results, res)

  #test sim components
  res = test_simcomponents()
  results = vcat(results, res)

  #test single rollout
  res = test_rollout()
  results = vcat(results, res)

  print_results(results)

  return results
end
