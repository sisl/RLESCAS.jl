import RLESMDPs: uniform_policy
import MCTSdpw: DPWParams, DPWModel, DPW, Depth

function defineMCTSParams(;
                          d::Depth = 50,
                          ec::Float64 = 100.0,
                          n::Int64 = 1000,
                          k::Float64 = 0.5,
                          alpha::Float64 = 0.85,
                          kp::Float64 = 1.0,
                          alphap::Float64 = 0.0,
                          clear_nodes::Bool = true,
                          maxtime_s::Float64 = realmax(Float64),
                          rng_seed::Uint64 = uint64(0)
                          )

  p = DPWParams(d, ec, n, k, alpha, kp, alphap, clear_nodes, maxtime_s, rng_seed)

  return p
end

function defineMCTS(mdp::RLESMDP, p::DPWParams)

  f = DPWModel(getTransitionModel(mdp),(s::State, rng::AbstractRNG) -> uniform_policy(mdp, s),
               (s::State, rng::AbstractRNG) -> uniform_policy(mdp, s))

  return DPW(p, f)
end
