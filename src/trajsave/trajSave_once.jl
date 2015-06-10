using SISLES.GenerativeModel

using CPUTime
using Dates
import Obj2Dict
using RunCases

type OnceStudy
  fileroot::String
end

OnceStudy(;
        fileroot::String = "trajSaveONCE"
        ) =
  OnceStudy(fileroot
          )

function trajSave(study_params::OnceStudy,
                       cases::Cases = Cases(Case());
                       outdir::String = "./"
                       )

  pmap(case -> begin
         starttime_us = CPUtime_us()
         startnow = string(now())

         sim_params = extract_params!(defineSimParams(), case, "sim_params")
         mdp_params = extract_params!(defineMDPParams(), case, "mdp_params")
         study_params = extract_params!(study_params, case, "study_params")

         sim = defineSim(sim_params)
         mdp = defineMDP(sim, mdp_params)

         simLog = SimLog()
         addObservers!(simLog, mdp)

         reward, action_seqs = directSample(getTransitionModel(mdp), mdp, uniform_policy)

         notifyObserver(sim, "run_info", Any[reward, sim.md_time, sim.hmd, sim.vmd, sim.label_as_nmac])

         compute_info = ComputeInfo(startnow,
                                    string(now()),
                                    gethostname(),
                                    (CPUtime_us() - starttime_us) / 1e6)


         sav = SaveDict()
         sav["run_type"] = "ONCE"
         sav["compute_info"] = Obj2Dict.to_dict(compute_info)
         sav["sim_params"] = Obj2Dict.to_dict(sim.params)
         sav["mdp_params"] = Obj2Dict.to_dict(mdp.params)
         sav["sim_log"] = simLog

         fileroot_ = "$(study_params.fileroot)_$(sim.string_id)"
         trajSave(joinpath(outdir, fileroot_), sav)

         return reward
       end,

       cases)
end
