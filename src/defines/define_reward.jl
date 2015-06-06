using SISLES
using SISLES.WorldModel
using SISLES.GenerativeModel
using SISLES.PilotResponse
using SISLES.ObserverImpl
import SISLES.addObserver
import ACASX_Common

const NMAC_REWARD = 0.0
const RESPONSE_FILTER_THRESH = 8 #seconds #TODO: save this somewhere in log file

function get_reward(sim::Union(ACASX_EvE, ACASX_Multi))

  reward = sim.step_logProb

  if ACASX_Common.isEndState(sim)

    if ACASX_Common.NMAC_occurred(sim) && response_filter(sim.pr, RESPONSE_FILTER_THRESH)
      reward += NMAC_REWARD
      sim.label_as_nmac = true
    else
      reward += -sim.md
      sim.label_as_nmac = false
    end

  end

  return reward
end

#returns true if at least 1 aircraft responds within response_thresh seconds
response_filter(pr::Vector, resp_thresh) = any(map(p -> response_filter_(p, resp_thresh), pr))

response_filter_(pr::StochasticLinearPR, resp_thres::Int64) = pr.response_time <= resp_thresh

function response_filter_(pr::LLDetPR, resp_thresh::Int64)

  pr.initial_resp_time <= resp_thresh && pr.subsequent_resp_time <= resp_thresh
end
