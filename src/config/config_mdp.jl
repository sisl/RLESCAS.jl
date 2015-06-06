using SISLES
using SISLES.GenerativeModel
using RLESMDPs

function defineMDPParams(;
                         max_steps::Int64 = 50,
                         action_counter_init::Uint32 = uint32(0),
                         action_counter_reset::Union(Uint32, Nothing) = nothing)
  p = RLESMDP_params()

  p.max_steps = max_steps
  p.action_counter_init = action_counter_init
  p.action_counter_reset = action_counter_reset

  return p
end

function defineMDP(sim::AbstractGenerativeModel, p::RLESMDP_params)

  return RLESMDP(p, sim, GenerativeModel.initialize, GenerativeModel.step,
                 GenerativeModel.isEndState, get_reward)
end
