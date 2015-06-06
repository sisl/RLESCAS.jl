using SISLES.GenerativeModel

using CPUTime
using Dates
import Obj2Dict
using RunCases

type MCBestStudy
  fileroot::String
  trial::Int64
  nsamples::Int64
  maxtime_s::Float64
end

MCBestStudy(;
       fileroot::String = "trajSaveMCBEST",
       trial::Int64 = 0,
       nsamples::Int64 = 200,
       maxtime_s::Float64 = realmax(Float64)
       ) =
  MCBestStudy(fileroot,
         trial,
         nsamples,
         maxtime_s
         )

type MCBestStudyResults
  nsamples::Int64    # actual number of samples used, i.e., when limited by time
  rewards::Vector{Float64}  #vector of all the rewards
end

MCBestStudyResults() = MCBestStudyResults(0, Float64[])


function trajSave(study_params::MCBestStudy,
                  runcases::Vector{RunCase} = RunCase[RunCase()];
                  outdir::String = "./")

  pmap(case->begin
         starttime_us = CPUtime_us()
         startnow = string(now())

         sim_params = extract_params!(defineSimParams(), case, "sim_params")
         mdp_params = extract_params!(defineMDPParams(), case, "mdp_params")
         study_params = extract_params!(study_params, case, "study_params")

         sim = defineSim(sim_params)
         mdp = defineMDP(sim, mdp_params)

         #generate different samples by varying the action counter initial value
         function init(i::Int)
           mdp.action_counter = uint32(hash(i + study_params.trial * study_params.nsamples))
           return getTransitionModel(mdp), mdp
         end

         rewards, action_seqs, nsamples = directSample(init, uniform_policy,
                                                       study_params.nsamples,
                                                       maxtime_s = study_params.maxtime_s)

         study_results = MCBestStudyResults(nsamples,
                                            rewards)

         besti = indmax(rewards)
         model, mdp = init(besti)

         #replay to get the logs
         simLog = SimLog()
         addObservers!(simLog, mdp)

         reward, action_seq = directSample(model, mdp, uniform_policy)

         notifyObserver(sim, "run_info", Any[reward, sim.md_time, sim.hmd, sim.vmd, sim.label_as_nmac])

         #sanity check replay
         @test reward == rewards[besti]
         @test action_seq == action_seqs[besti]

         compute_info = ComputeInfo(startnow,
                                    string(now()),
                                    gethostname(),
                                    (CPUtime_us() - starttime_us) / 1e6)

         #Save
         sav = SaveDict()
         sav["run_type"] = "MCBEST"
         sav["compute_info"] = Obj2Dict.to_dict(compute_info)
         sav["study_params"] = Obj2Dict.to_dict(study_params)
         sav["study_results"] = Obj2Dict.to_dict(study_results)
         sav["sim_params"] = Obj2Dict.to_dict(mdp.sim.params)
         sav["mdp_params"] = Obj2Dict.to_dict(mdp.params)
         sav["sim_log"] = simLog

         fileroot_ = "$(study_params.fileroot)_$(sim.string_id)"
         trajSave(joinpath(outdir, fileroot_), sav)

         return reward
       end,

       runcases)
end
